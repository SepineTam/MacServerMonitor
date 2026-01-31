//
//  NetworkSampler.swift
//  MacServerMonitor
//
//  Network connectivity sampler
//

import Foundation
import Network

/// Network connectivity metrics sampler
final class NetworkSampler {
    // MARK: - Singleton
    static let shared = NetworkSampler()

    private init() {}

    // MARK: - State
    private var consecutiveFailures = 0
    private let requiredFailures = 2

    // MARK: - Sampling

    /// Sample network connectivity
    func sample(target: String) async -> NetworkMetrics {
        let status = await checkConnectivity(target: target)

        switch status {
        case .normal:
            consecutiveFailures = 0
            let now = Date().timeIntervalSince1970
            return NetworkMetrics(status: .normal, lastOkTimestamp: now)
        case .down:
            consecutiveFailures += 1
            if consecutiveFailures >= requiredFailures {
                // Return last OK timestamp as 0 if not set
                return NetworkMetrics(status: .down, lastOkTimestamp: 0)
            } else {
                // Still considered normal until we hit the threshold
                let now = Date().timeIntervalSince1970
                return NetworkMetrics(status: .normal, lastOkTimestamp: now)
            }
        }
    }

    // MARK: - Private Methods

    private func checkConnectivity(target: String) async -> NetworkStatus {
        if target == "gateway" {
            return await checkGatewayConnectivity()
        } else {
            return await checkHostConnectivity(host: target)
        }
    }

    private func checkGatewayConnectivity() async -> NetworkStatus {
        // Use NWPathMonitor to check if network is available
        return await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let lock = NSLock()
            var isDone = false

            monitor.pathUpdateHandler = { path in
                lock.lock()
                defer { lock.unlock() }
                if !isDone {
                    isDone = true
                    monitor.cancel()

                    if path.status == .satisfied {
                        continuation.resume(returning: .normal)
                    } else {
                        continuation.resume(returning: .down)
                    }
                }
            }

            let queue = DispatchQueue(label: "NetworkMonitor")
            monitor.start(queue: queue)

            // Timeout after 5 seconds
            DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                lock.lock()
                defer { lock.unlock() }
                if !isDone {
                    isDone = true
                    monitor.cancel()
                    continuation.resume(returning: .down)
                }
            }
        }
    }

    private func checkHostConnectivity(host: String) async -> NetworkStatus {
        // Try to create a TCP connection to the host
        // Use port 80 (common HTTP port) or 443 (HTTPS)
        let ports: [UInt16] = [80, 443]

        for port in ports {
            let result = await tryConnect(host: host, port: port)
            if result {
                return .normal
            }
        }

        return .down
    }

    private func tryConnect(host: String, port: UInt16) async -> Bool {
        return await withCheckedContinuation { continuation in
            var hint = addrinfo()
            hint.ai_family = AF_UNSPEC
            hint.ai_socktype = SOCK_STREAM

            var result: UnsafeMutablePointer<addrinfo>?
            let status = getaddrinfo(host, String(port), &hint, &result)

            guard status == 0 else {
                continuation.resume(returning: false)
                return
            }

            var sockfd: Int32 = -1
            var success = false

            var infoPtr = result
            while let info = infoPtr {
                let ai = info.pointee
                sockfd = socket(ai.ai_family, ai.ai_socktype, ai.ai_protocol)

                if sockfd >= 0 {
                    // Set non-blocking
                    _ = fcntl(sockfd, F_SETFL, O_NONBLOCK)

                    let connectResult = connect(sockfd, ai.ai_addr, ai.ai_addrlen)

                    if connectResult == 0 || errno == EINPROGRESS {
                        // Wait a bit for connection
                        usleep(100_000) // 100ms

                        var error = Int32(0)
                        var len = socklen_t(MemoryLayout.size(ofValue: error))
                        getsockopt(sockfd, SOL_SOCKET, SO_ERROR, &error, &len)

                        if error == 0 {
                            success = true
                        }
                    }

                    close(sockfd)
                    break
                }

                infoPtr = info.pointee.ai_next
            }

            freeaddrinfo(result)
            continuation.resume(returning: success)
        }
    }

    /// Reset failure counter
    func reset() {
        consecutiveFailures = 0
    }
}
