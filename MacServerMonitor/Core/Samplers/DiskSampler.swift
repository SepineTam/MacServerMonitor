//
//  DiskSampler.swift
//  MacServerMonitor
//
//  Disk usage sampler
//

import Foundation

/// Disk usage metrics sampler
final class DiskSampler {
    // MARK: - Singleton
    static let shared = DiskSampler()

    private init() {}

    // MARK: - Sampling

    /// Sample disk usage for root volume
    func sample() -> DiskMetrics {
        do {
            let fileURL = URL(fileURLWithPath: "/")
            let values = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])

            guard let totalCapacity = values.volumeTotalCapacity,
                  let availableCapacity = values.volumeAvailableCapacity else {
                return DiskMetrics(usedPercent: 0)
            }

            let usedCapacity = totalCapacity - availableCapacity
            let usedPercent = Double(usedCapacity) / Double(totalCapacity) * 100

            return DiskMetrics(usedPercent: usedPercent)
        } catch {
            return DiskMetrics(usedPercent: 0)
        }
    }
}
