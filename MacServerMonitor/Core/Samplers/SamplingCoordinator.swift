//
//  SamplingCoordinator.swift
//  MacServerMonitor
//
//  Coordinates periodic sampling of all metrics
//

import Foundation

/// Coordinates periodic sampling of system metrics
final class SamplingCoordinator {
    // MARK: - Singleton
    static let shared = SamplingCoordinator()

    private init() {}

    // MARK: - State
    private var timer: Timer?
    private var isRunning = false

    // MARK: - Public Methods

    /// Start periodic sampling
    func start() {
        guard !isRunning else { return }

        isRunning = true
        scheduleNextSampling()
    }

    /// Stop periodic sampling
    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    /// Trigger immediate sampling (e.g., for testing or manual refresh)
    func sampleNow() async {
        await performSampling()
    }

    // MARK: - Private Methods

    private func scheduleNextSampling() {
        guard isRunning else { return }

        timer?.invalidate()

        let interval = TimeInterval(SettingsStore.shared.refreshIntervalSeconds)

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task {
                await self?.performSampling()
            }
        }

        // Run first sample immediately
        Task {
            await performSampling()
        }
    }

    @MainActor
    private func performSampling() async {
        // Check if we should still be running
        guard isRunning else { return }

        // Reschedule if interval changed
        let currentInterval = SettingsStore.shared.refreshIntervalSeconds
        if let timer = timer, timer.timeInterval != TimeInterval(currentInterval) {
            scheduleNextSampling()
            return
        }

        // Sample all metrics
        let timestamp = Date().timeIntervalSince1970

        // CPU and Memory can be sampled synchronously
        let cpu = CpuSampler.shared.sample()
        let memory = MemorySampler.shared.sample()
        let disk = DiskSampler.shared.sample()

        // Network requires async
        let networkTarget = SettingsStore.shared.networkProbeTarget
        let network = await NetworkSampler.shared.sample(target: networkTarget)

        // Create snapshot
        let snapshot = MetricsSnapshot(
            timestamp: timestamp,
            memory: memory,
            cpu: cpu,
            disk: disk,
            network: network
        )

        // Store snapshot
        MetricStore.shared.addSnapshot(snapshot)

        // Evaluate alerts
        AlertEngine.shared.evaluate(snapshot: snapshot)
    }

    /// Restart coordinator (e.g., when settings change)
    func restart() {
        if isRunning {
            stop()
            start()
        }
    }
}
