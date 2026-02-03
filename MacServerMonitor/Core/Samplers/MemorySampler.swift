//
//  MemorySampler.swift
//  MacServerMonitor
//
//  Memory usage sampler
//

import Foundation

/// Memory usage metrics sampler
final class MemorySampler {
    // MARK: - Singleton
    static let shared = MemorySampler()

    private init() {}

    // MARK: - Sampling

    /// Sample memory usage
    func sample() -> MemoryMetrics {
        var stats = vm_statistics64()
        var count = UInt32(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return MemoryMetrics(totalBytes: 0, usedBytes: 0, usedPercent: 0)
        }

        // Get total memory
        var totalMemory: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &totalMemory, &size, nil, 0)

        // Calculate used memory
        let pageSize = UInt64(vm_page_size)
        let activePages = UInt64(stats.active_count)
        let wiredPages = UInt64(stats.wire_count)
        let compressedPages = UInt64(stats.compressor_page_count)

        let usedBytes = (activePages + wiredPages) * pageSize
        let compressedBytes = compressedPages * pageSize
        let usedPercent = Double(usedBytes) / Double(totalMemory) * 100

        // Get swap usage
        var swapInfo = xsw_usage()
        var swapSize = MemoryLayout<xsw_usage>.size
        var swapUsedBytes: UInt64?

        if sysctlbyname("vm.swapusage", &swapInfo, &swapSize, nil, 0) == 0 {
            swapUsedBytes = swapInfo.xsu_used
        }

        return MemoryMetrics(
            totalBytes: totalMemory,
            usedBytes: usedBytes,
            usedPercent: usedPercent,
            compressedBytes: compressedBytes > 0 ? compressedBytes : nil,
            swapUsedBytes: swapUsedBytes
        )
    }
}
