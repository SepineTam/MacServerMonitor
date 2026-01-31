//
//  MemoryMetrics.swift
//  MacServerMonitor
//
//  Memory metrics model
//

import Foundation

/// Memory usage metrics
struct MemoryMetrics: Codable, Equatable {
    let totalBytes: UInt64
    let usedBytes: UInt64
    let usedPercent: Double
    let compressedBytes: UInt64?
    let swapUsedBytes: UInt64?

    private enum CodingKeys: String, CodingKey {
        case totalBytes = "total_bytes"
        case usedBytes = "used_bytes"
        case usedPercent = "used_percent"
        case compressedBytes = "compressed_bytes"
        case swapUsedBytes = "swap_used_bytes"
    }

    init(totalBytes: UInt64, usedBytes: UInt64, usedPercent: Double,
         compressedBytes: UInt64? = nil, swapUsedBytes: UInt64? = nil) {
        self.totalBytes = totalBytes
        self.usedBytes = usedBytes
        self.usedPercent = usedPercent
        self.compressedBytes = compressedBytes
        self.swapUsedBytes = swapUsedBytes
    }
}
