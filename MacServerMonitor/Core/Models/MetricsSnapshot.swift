//
//  MetricsSnapshot.swift
//  MacServerMonitor
//
//  Metrics snapshot model
//

import Foundation

/// Complete metrics snapshot at a point in time
struct MetricsSnapshot: Codable, Equatable {
    let timestamp: TimeInterval
    let memory: MemoryMetrics
    let cpu: CpuMetrics
    let disk: DiskMetrics
    let network: NetworkMetrics

    init(timestamp: TimeInterval, memory: MemoryMetrics, cpu: CpuMetrics,
         disk: DiskMetrics, network: NetworkMetrics) {
        self.timestamp = timestamp
        self.memory = memory
        self.cpu = cpu
        self.disk = disk
        self.network = network
    }
}
