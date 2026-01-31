//
//  CpuMetrics.swift
//  MacServerMonitor
//
//  CPU metrics model
//

import Foundation

/// CPU usage metrics
struct CpuMetrics: Codable, Equatable {
    let usagePercent: Double
    let load1: Double
    let load5: Double
    let load15: Double

    private enum CodingKeys: String, CodingKey {
        case usagePercent = "usage_percent"
        case load1
        case load5
        case load15
    }

    init(usagePercent: Double, load1: Double, load5: Double, load15: Double) {
        self.usagePercent = usagePercent
        self.load1 = load1
        self.load5 = load5
        self.load15 = load15
    }
}
