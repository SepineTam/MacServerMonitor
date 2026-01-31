//
//  HttpServer.swift
//  MacServerMonitor
//
//  HTTP server for LAN monitoring
//

import Foundation
import Network

/// HTTP server for read-only monitoring access
final class HttpServer {
    // MARK: - Singleton
    static let shared = HttpServer()

    private init() {}

    // MARK: - State
    private var listener: NWListener?
    private var isRunning = false

    // MARK: - Public Methods

    /// Start the HTTP server
    func start() {
        guard !isRunning else { return }

        let settings = SettingsStore.shared
        guard settings.httpServerEnabled else { return }

        let port = NWEndpoint.Port(rawValue: UInt16(settings.httpServerPort))!
        let config = NWParameters.tcp

        // Configure for HTTP
        config.allowLocalEndpointReuse = true
        config.allowFastOpen = true

        do {
            listener = try NWListener(using: config, on: port)
            listener?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    self?.isRunning = true
                    print("[HTTP] Server started on port \(settings.httpServerPort)")
                case .failed(let error):
                    print("[HTTP] Server failed: \(error)")
                    self?.stop()
                default:
                    break
                }
            }

            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }

            listener?.start(queue: .global())
        } catch {
            print("[HTTP] Failed to start server: \(error)")
        }
    }

    /// Stop the HTTP server
    func stop() {
        isRunning = false
        listener?.cancel()
        listener = nil
    }

    /// Restart the server (e.g., when settings change)
    func restart() {
        stop()
        start()
    }

    // MARK: - Private Methods

    private func handleConnection(_ connection: NWConnection) {
        connection.stateUpdateHandler = { state in
            if case .failed = state {
                connection.cancel()
            }
        }

        connection.start(queue: .global())

        // Read request
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self?.processRequest(data, connection: connection)
            }
            if isComplete || error != nil {
                connection.cancel()
            }
        }
    }

    private func processRequest(_ data: Data, connection: NWConnection) {
        guard let requestString = String(data: data, encoding: .utf8) else {
            sendResponse(connection: connection, statusCode: 400, body: "Bad Request")
            return
        }

        // Parse HTTP request
        let lines = requestString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            sendResponse(connection: connection, statusCode: 400, body: "Bad Request")
            return
        }

        let components = requestLine.components(separatedBy: " ")
        guard components.count >= 2 else {
            sendResponse(connection: connection, statusCode: 400, body: "Bad Request")
            return
        }

        let method = components[0]
        let path = components[1]

        // Extract authorization header
        let token = extractToken(from: lines)

        // Verify token
        guard verifyToken(token) else {
            sendResponse(connection: connection, statusCode: 401, body: "Unauthorized")
            return
        }

        // Handle GET requests only
        guard method == "GET" else {
            sendResponse(connection: connection, statusCode: 405, body: "Method Not Allowed")
            return
        }

        // Route request
        switch path {
        case "/api/v1/status":
            handleStatus(connection: connection)
        case "/api/v1/series":
            handleSeries(connection: connection, query: extractQuery(from: lines))
        case "/api/v1/config":
            handleConfig(connection: connection)
        default:
            sendResponse(connection: connection, statusCode: 404, body: "Not Found")
        }
    }

    private func extractToken(from lines: [String]) -> String? {
        for line in lines {
            if line.lowercased().hasPrefix("authorization:") {
                let parts = line.dropFirst("authorization:".count).trimmingCharacters(in: .whitespaces)
                if parts.lowercased().hasPrefix("bearer ") {
                    return String(parts.dropFirst(7))
                }
            }
        }
        return nil
    }

    private func extractQuery(from lines: [String]) -> [String: String] {
        var query: [String: String] = [:]
        for line in lines {
            if line.hasPrefix("GET ") {
                if let queryRange = line.range(of: "?"), let endRange = line.range(of: " ", range: queryRange.upperBound..<line.endIndex) {
                    let queryString = String(line[queryRange.upperBound..<endRange.lowerBound])
                    query = parseQueryString(queryString)
                }
            }
        }
        return query
    }

    private func parseQueryString(_ query: String) -> [String: String] {
        var result: [String: String] = [:]
        for pair in query.components(separatedBy: "&") {
            let components = pair.components(separatedBy: "=")
            if components.count == 2 {
                result[components[0]] = components[1]
            }
        }
        return result
    }

    private func verifyToken(_ token: String?) -> Bool {
        guard let token = token else { return false }
        return token == SettingsStore.shared.httpServerToken
    }

    private func handleStatus(connection: NWConnection) {
        guard let snapshot = MetricStore.shared.latestSnapshot else {
            sendResponse(connection: connection, statusCode: 503, body: "Service Unavailable")
            return
        }

        let response = StatusResponse(
            timestamp: snapshot.timestamp,
            metrics: StatusResponse.Metrics(
                memory: snapshot.memory,
                cpu: snapshot.cpu,
                disk: snapshot.disk,
                network: snapshot.network
            ),
            alerts: StatusResponse.Alerts(
                active: AlertEngine.shared.isAnyAlertActive,
                items: AlertEngine.shared.getAllAlertStatuses().map { status in
                    StatusResponse.AlertItem(
                        type: status.type.rawValue,
                        status: status.state.isActive ? "alerting" : "normal",
                        sinceTimestamp: status.state.isActive ? Date().timeIntervalSince1970 : 0,
                        nextSoundTimestamp: status.nextSoundTime ?? 0
                    )
                }
            )
        )

        sendJSONResponse(connection: connection, body: response)
    }

    private func handleSeries(connection: NWConnection, query: [String: String]) {
        var points = 60
        if let pointsStr = query["points"], let pointsInt = Int(pointsStr) {
            points = min(300, max(1, pointsInt))
        }

        let series = MetricStore.shared.getSeries(points: points)
        let response = SeriesResponse(
            timestamp: Date().timeIntervalSince1970,
            series: SeriesResponse.Series(
                memoryUsedPercent: series.memoryUsedPercent,
                cpuUsagePercent: series.cpuUsagePercent,
                diskUsedPercent: series.diskUsedPercent,
                networkStatus: series.networkStatus
            )
        )

        sendJSONResponse(connection: connection, body: response)
    }

    private func handleConfig(connection: NWConnection) {
        let settings = SettingsStore.shared
        let response = ConfigResponse(
            refreshIntervalSeconds: settings.refreshIntervalSeconds,
            thresholds: ConfigResponse.Thresholds(
                memoryPercent: settings.memoryThresholdPercent,
                cpuPercent: settings.cpuThresholdPercent,
                diskPercent: settings.diskThresholdPercent
            ),
            networkProbeTarget: settings.networkProbeTarget,
            port: settings.httpServerPort
        )

        sendJSONResponse(connection: connection, body: response)
    }

    private func sendResponse(connection: NWConnection, statusCode: Int, body: String) {
        let statusText: String
        switch statusCode {
        case 200: statusText = "OK"
        case 400: statusText = "Bad Request"
        case 401: statusText = "Unauthorized"
        case 404: statusText = "Not Found"
        case 405: statusText = "Method Not Allowed"
        case 503: statusText = "Service Unavailable"
        default: statusText = "Unknown"
        }

        let response = """
        HTTP/1.1 \(statusCode) \(statusText)\r
        Content-Type: text/plain\r
        Content-Length: \(body.utf8.count)\r
        Connection: close\r
        \r
        \(body)
        """

        if let data = response.data(using: .utf8) {
            connection.send(content: data, completion: .contentProcessed { _ in
                connection.cancel()
            })
        }
    }

    private func sendJSONResponse<T: Encodable>(connection: NWConnection, body: T) {
        guard let jsonData = try? JSONEncoder().encode(body) else {
            sendResponse(connection: connection, statusCode: 500, body: "Internal Server Error")
            return
        }

        let json = String(data: jsonData, encoding: .utf8)!
        let response = """
        HTTP/1.1 200 OK\r
        Content-Type: application/json\r
        Content-Length: \(json.utf8.count)\r
        Connection: close\r
        \r
        \(json)
        """

        if let data = response.data(using: .utf8) {
            connection.send(content: data, completion: .contentProcessed { _ in
                connection.cancel()
            })
        }
    }
}

// MARK: - Response Models

private struct StatusResponse: Codable {
    let timestamp: TimeInterval
    let metrics: Metrics
    let alerts: Alerts

    struct Metrics: Codable {
        let memory: MemoryMetrics
        let cpu: CpuMetrics
        let disk: DiskMetrics
        let network: NetworkMetrics
    }

    struct Alerts: Codable {
        let active: Bool
        let items: [AlertItem]
    }

    struct AlertItem: Codable {
        let type: String
        let status: String
        let sinceTimestamp: TimeInterval
        let nextSoundTimestamp: TimeInterval
    }
}

private struct SeriesResponse: Codable {
    let timestamp: TimeInterval
    let series: Series

    struct Series: Codable {
        let memoryUsedPercent: [Double]
        let cpuUsagePercent: [Double]
        let diskUsedPercent: [Double]
        let networkStatus: [String]
    }
}

private struct ConfigResponse: Codable {
    let refreshIntervalSeconds: Int
    let thresholds: Thresholds
    let networkProbeTarget: String
    let port: Int

    struct Thresholds: Codable {
        let memoryPercent: Double
        let cpuPercent: Double
        let diskPercent: Double
    }
}
