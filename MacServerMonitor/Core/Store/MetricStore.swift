//
//  MetricStore.swift
//  MacServerMonitor
//
//  Metrics storage with ring buffers
//

import Foundation

/// Time series data for metrics
struct MetricSeries: Codable {
    let memoryUsedPercent: [Double]
    let cpuUsagePercent: [Double]
    let diskUsedPercent: [Double]
    let networkStatus: [String]

    private enum CodingKeys: String, CodingKey {
        case memoryUsedPercent = "memory_used_percent"
        case cpuUsagePercent = "cpu_usage_percent"
        case diskUsedPercent = "disk_used_percent"
        case networkStatus = "network_status"
    }
}

/// In-memory metrics store with ring buffers
final class MetricStore {
    // MARK: - Singleton
    static let shared = MetricStore()

    private init() {}

    // MARK: - Configuration
    private(set) var maxPoints: Int = 60

    func setMaxPoints(_ points: Int) {
        maxPoints = max(1, min(300, points))
        trimBuffers()
    }

    // MARK: - Latest Snapshot
    private var _latestSnapshot: MetricsSnapshot?

    var latestSnapshot: MetricsSnapshot? {
        _latestSnapshot
    }

    // MARK: - Ring Buffers
    private var memoryBuffer: [Double] = []
    private var cpuBuffer: [Double] = []
    private var diskBuffer: [Double] = []
    private var networkBuffer: [NetworkStatus] = []

    // MARK: - Public Methods

    /// Add a new snapshot to the store
    func addSnapshot(_ snapshot: MetricsSnapshot) {
        _latestSnapshot = snapshot

        // Add to ring buffers
        memoryBuffer.append(snapshot.memory.usedPercent)
        cpuBuffer.append(snapshot.cpu.usagePercent)
        diskBuffer.append(snapshot.disk.usedPercent)
        networkBuffer.append(snapshot.network.status)

        trimBuffers()
    }

    /// Get series data
    func getSeries(points: Int? = nil) -> MetricSeries {
        let count = points.map { min($0, maxPoints) } ?? maxPoints

        return MetricSeries(
            memoryUsedPercent: getLast(memoryBuffer, count: count),
            cpuUsagePercent: getLast(cpuBuffer, count: count),
            diskUsedPercent: getLast(diskBuffer, count: count),
            networkStatus: getLast(networkBuffer, count: count).map { $0.rawValue }
        )
    }

    // MARK: - Private Methods

    private func trimBuffers() {
        while memoryBuffer.count > maxPoints {
            memoryBuffer.removeFirst()
        }
        while cpuBuffer.count > maxPoints {
            cpuBuffer.removeFirst()
        }
        while diskBuffer.count > maxPoints {
            diskBuffer.removeFirst()
        }
        while networkBuffer.count > maxPoints {
            networkBuffer.removeFirst()
        }
    }

    private func getLast<T>(_ array: [T], count: Int) -> [T] {
        if array.count <= count {
            return array
        }
        return Array(array.suffix(count))
    }

    /// Clear all stored data
    func clear() {
        _latestSnapshot = nil
        memoryBuffer.removeAll()
        cpuBuffer.removeAll()
        diskBuffer.removeAll()
        networkBuffer.removeAll()
    }
}
