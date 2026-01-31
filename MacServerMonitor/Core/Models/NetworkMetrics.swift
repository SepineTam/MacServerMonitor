//
//  NetworkMetrics.swift
//  MacServerMonitor
//
//  Network metrics model
//

import Foundation

/// Network connectivity status
enum NetworkStatus: String, Codable {
    case normal = "normal"
    case down = "down"
}

/// Network connectivity metrics
struct NetworkMetrics: Codable, Equatable {
    let status: NetworkStatus
    let lastOkTimestamp: TimeInterval

    private enum CodingKeys: String, CodingKey {
        case status
        case lastOkTimestamp = "last_ok_timestamp"
    }

    init(status: NetworkStatus, lastOkTimestamp: TimeInterval) {
        self.status = status
        self.lastOkTimestamp = lastOkTimestamp
    }
}
