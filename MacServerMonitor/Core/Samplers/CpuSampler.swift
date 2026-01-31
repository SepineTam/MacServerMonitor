//
//  CpuSampler.swift
//  MacServerMonitor
//
//  CPU usage sampler
//

import Foundation

/// CPU usage metrics sampler
final class CpuSampler {
    // MARK: - Singleton
    static let shared = CpuSampler()

    private init() {
        // Initialize previous CPU info for usage calculation
        updateCpuInfo()
    }

    // MARK: - CPU Usage Tracking
    private var previousTicks: UInt64 = 0
    private var previousIdle: UInt64 = 0

    /// Sample CPU usage and load averages
    func sample() -> CpuMetrics {
        let usagePercent = calculateCpuUsage()
        let loadAverages = getLoadAverages()

        return CpuMetrics(
            usagePercent: usagePercent,
            load1: loadAverages.0,
            load5: loadAverages.1,
            load15: loadAverages.2
        )
    }

    // MARK: - Private Methods

    private func updateCpuInfo() {
        var ticks: UInt64 = 0
        var idle: UInt64 = 0

        var numCpuInfo = UInt32(0)
        var cpuInfo: processor_info_array_t?
        var numCpuInfoData = mach_msg_type_number_t(0)

        let cpuResult = host_processor_info(mach_host_self(),
                                           PROCESSOR_CPU_LOAD_INFO,
                                           &numCpuInfo,
                                           &cpuInfo,
                                           &numCpuInfoData)

        if cpuResult == KERN_SUCCESS, let cpuInfo = cpuInfo {
            let data = cpuInfo.withMemoryRebound(to: processor_cpu_load_info_data_t.self, capacity: Int(numCpuInfo)) { ptr in
                ptr
            }

            for i in 0..<Int(numCpuInfo) {
                ticks += UInt64(data[i].cpu_ticks.0) + UInt64(data[i].cpu_ticks.1) + UInt64(data[i].cpu_ticks.2) + UInt64(data[i].cpu_ticks.3)
                idle += UInt64(data[i].cpu_ticks.2)
            }

            let size = vm_size_t(Int(numCpuInfo) * MemoryLayout<processor_cpu_load_info_data_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(UInt64(Int(bitPattern: cpuInfo))), size)
        }

        previousTicks = ticks
        previousIdle = idle
    }

    private func calculateCpuUsage() -> Double {
        var currentTicks: UInt64 = 0
        var currentIdle: UInt64 = 0

        var numCpuInfo = UInt32(0)
        var cpuInfo: processor_info_array_t?
        var numCpuInfoData = mach_msg_type_number_t(0)

        let result = host_processor_info(mach_host_self(),
                                        PROCESSOR_CPU_LOAD_INFO,
                                        &numCpuInfo,
                                        &cpuInfo,
                                        &numCpuInfoData)

        if result == KERN_SUCCESS, let cpuInfo = cpuInfo {
            let data = cpuInfo.withMemoryRebound(to: processor_cpu_load_info_data_t.self, capacity: Int(numCpuInfo)) { ptr in
                ptr
            }

            for i in 0..<Int(numCpuInfo) {
                currentTicks += UInt64(data[i].cpu_ticks.0) + UInt64(data[i].cpu_ticks.1) + UInt64(data[i].cpu_ticks.2) + UInt64(data[i].cpu_ticks.3)
                currentIdle += UInt64(data[i].cpu_ticks.2)
            }

            let size = vm_size_t(Int(numCpuInfo) * MemoryLayout<processor_cpu_load_info_data_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(UInt64(Int(bitPattern: cpuInfo))), size)
        }

        let totalDelta = currentTicks - previousTicks
        let idleDelta = currentIdle - previousIdle

        updateCpuInfo()

        if totalDelta == 0 {
            return 0
        }

        let usage = 100.0 - Double(idleDelta) / Double(totalDelta) * 100.0
        return max(0, min(100, usage))
    }

    private func getLoadAverages() -> (Double, Double, Double) {
        var averages: [Double] = [0, 0, 0]
        let result = getloadavg(&averages, 3)

        if result == 3 {
            return (averages[0], averages[1], averages[2])
        }

        return (0, 0, 0)
    }
}
