//
//  DiskMetrics.swift
//  MacServerMonitor
//
//  Disk metrics model
//

import Foundation

/// Disk usage metrics
struct DiskMetrics: Codable, Equatable {
    let usedPercent: Double

    private enum CodingKeys: String, CodingKey {
        case usedPercent = "used_percent"
    }

    init(usedPercent: Double) {
        self.usedPercent = usedPercent
    }
}
