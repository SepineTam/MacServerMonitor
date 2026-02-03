//
//  Device.swift
//  MacServerMonitor
//
//  Device model for multi-device monitoring
//

import Foundation

/// Device information
struct Device: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var hostname: String
    var address: String
    var port: Int
    var isEnabled: Bool
    var lastSeen: Date
    var status: DeviceStatus
    var connectionType: ConnectionType

    init(
        id: UUID = UUID(),
        name: String,
        hostname: String,
        address: String,
        port: Int = 17890,
        isEnabled: Bool = true,
        status: DeviceStatus = .unknown,
        connectionType: ConnectionType = .local
    ) {
        self.id = id
        self.name = name
        self.hostname = hostname
        self.address = address
        self.port = port
        self.isEnabled = isEnabled
        self.lastSeen = Date()
        self.status = status
        self.connectionType = connectionType
    }

    var isLocal: Bool {
        connectionType == .local
    }

    var baseURL: String {
        "http://\(address):\(port)"
    }

    var fullName: String {
        "\(name) (\(hostname))"
    }
}

/// Device connection status
enum DeviceStatus: String, Codable {
    case online
    case offline
    case unknown
    case error

    var color: String {
        switch self {
        case .online: return "green"
        case .offline: return "red"
        case .unknown: return "gray"
        case .error: return "orange"
        }
    }
}

/// Device connection type
enum ConnectionType: String, Codable {
    case local
    case remote
    case wireless
}

/// Device metrics from remote device
struct DeviceMetrics: Identifiable, Codable {
    let deviceId: UUID
    let deviceName: String
    let hostname: String
    let snapshot: MetricsSnapshot
    let timestamp: Date

    var id: UUID { deviceId }

    var isStale: Bool {
        Date().timeIntervalSince(timestamp) > 30 // 30 seconds
    }
}

/// Local device information
struct LocalDeviceInfo {
    static let shared = LocalDeviceInfo()

    let hostname: String
    let name: String

    private init() {
        // Get hostname
        let size = Int(MAXHOSTNAMELEN)
        var hostnameBuffer = [CChar](repeating: 0, count: Int(MAXHOSTNAMELEN))
        gethostname(&hostnameBuffer, size)
        self.hostname = String(cString: hostnameBuffer)

        // Get computer name
        let host = ProcessInfo.processInfo.hostName
        self.name = host.components(separatedBy: ".").first ?? hostname
    }
}
