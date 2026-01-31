//
//  SettingsStore.swift
//  MacServerMonitor
//
//  UserDefaults wrapper for application settings
//

import Foundation
import Combine

/// Settings keys - internal to prevent typos
private enum SettingsKey: String {
    case refreshIntervalSeconds = "refresh_interval_seconds"
    case memoryThresholdPercent = "memory_threshold_percent"
    case cpuThresholdPercent = "cpu_threshold_percent"
    case diskThresholdPercent = "disk_threshold_percent"
    case consecutiveSamplesToTrigger = "consecutive_samples_to_trigger"
    case alertRepeatMinutes = "alert_repeat_minutes"
    case networkProbeTarget = "network_probe_target"
    case httpServerEnabled = "http_server_enabled"
    case httpServerPort = "http_server_port"
    case httpServerToken = "http_server_token"
}

/// Settings store backed by UserDefaults
final class SettingsStore: ObservableObject {
    // MARK: - Singleton
    static let shared = SettingsStore()

    private let defaults: UserDefaults

    // MARK: - Refresh Settings
    @Published var refreshIntervalSeconds: Int

    // MARK: - Alert Thresholds
    @Published var memoryThresholdPercent: Double
    @Published var cpuThresholdPercent: Double
    @Published var diskThresholdPercent: Double

    // MARK: - Alert Behavior
    @Published var consecutiveSamplesToTrigger: Int
    @Published var alertRepeatMinutes: Int

    // MARK: - Network Settings
    @Published var networkProbeTarget: String

    // MARK: - HTTP Server Settings
    @Published var httpServerEnabled: Bool
    @Published var httpServerPort: Int

    private init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults

        // Initialize from UserDefaults or use defaults
        let refreshInterval = userDefaults.integer(forKey: SettingsKey.refreshIntervalSeconds.rawValue)
        self.refreshIntervalSeconds = refreshInterval == 0 ? 5 : refreshInterval

        let memoryThreshold = userDefaults.double(forKey: SettingsKey.memoryThresholdPercent.rawValue)
        self.memoryThresholdPercent = memoryThreshold == 0 ? 85.0 : memoryThreshold

        let cpuThreshold = userDefaults.double(forKey: SettingsKey.cpuThresholdPercent.rawValue)
        self.cpuThresholdPercent = cpuThreshold == 0 ? 90.0 : cpuThreshold

        let diskThreshold = userDefaults.double(forKey: SettingsKey.diskThresholdPercent.rawValue)
        self.diskThresholdPercent = diskThreshold == 0 ? 90.0 : diskThreshold

        let consecutiveSamples = userDefaults.integer(forKey: SettingsKey.consecutiveSamplesToTrigger.rawValue)
        self.consecutiveSamplesToTrigger = consecutiveSamples == 0 ? 2 : consecutiveSamples

        let alertRepeat = userDefaults.integer(forKey: SettingsKey.alertRepeatMinutes.rawValue)
        self.alertRepeatMinutes = alertRepeat == 0 ? 3 : alertRepeat

        self.networkProbeTarget = userDefaults.string(forKey: SettingsKey.networkProbeTarget.rawValue) ?? "gateway"

        let httpEnabled = userDefaults.object(forKey: SettingsKey.httpServerEnabled.rawValue)
        self.httpServerEnabled = httpEnabled == nil ? true : userDefaults.bool(forKey: SettingsKey.httpServerEnabled.rawValue)

        let httpPort = userDefaults.integer(forKey: SettingsKey.httpServerPort.rawValue)
        self.httpServerPort = httpPort == 0 ? 17890 : httpPort

        // Initialize token if not exists
        if userDefaults.string(forKey: SettingsKey.httpServerToken.rawValue) == nil {
            userDefaults.set(AppSettings.generateToken(), forKey: SettingsKey.httpServerToken.rawValue)
        }
    }

    // MARK: - Token Management

    var httpServerToken: String {
        get { defaults.string(forKey: SettingsKey.httpServerToken.rawValue) ?? "" }
        set { defaults.set(newValue, forKey: SettingsKey.httpServerToken.rawValue) }
    }

    // MARK: - Public Methods

    /// Get current settings as AppSettings struct
    var currentSettings: AppSettings {
        AppSettings(
            refreshIntervalSeconds: refreshIntervalSeconds,
            memoryThresholdPercent: memoryThresholdPercent,
            cpuThresholdPercent: cpuThresholdPercent,
            diskThresholdPercent: diskThresholdPercent,
            consecutiveSamplesToTrigger: consecutiveSamplesToTrigger,
            alertRepeatMinutes: alertRepeatMinutes,
            networkProbeTarget: networkProbeTarget,
            httpServerEnabled: httpServerEnabled,
            httpServerPort: httpServerPort,
            httpServerToken: httpServerToken
        )
    }

    /// Regenerate HTTP server token
    func regenerateToken() {
        httpServerToken = AppSettings.generateToken()
    }

    /// Reset all settings to defaults
    func resetToDefaults() {
        let defaults = AppSettings.default
        refreshIntervalSeconds = defaults.refreshIntervalSeconds
        memoryThresholdPercent = defaults.memoryThresholdPercent
        cpuThresholdPercent = defaults.cpuThresholdPercent
        diskThresholdPercent = defaults.diskThresholdPercent
        consecutiveSamplesToTrigger = defaults.consecutiveSamplesToTrigger
        alertRepeatMinutes = defaults.alertRepeatMinutes
        networkProbeTarget = defaults.networkProbeTarget
        httpServerEnabled = defaults.httpServerEnabled
        httpServerPort = defaults.httpServerPort
        sync()
        // Note: token is not reset on resetToDefaults()
    }

    /// Sync current values to UserDefaults
    func sync() {
        let validValues = [5, 10, 30]
        defaults.set(validValues.contains(refreshIntervalSeconds) ? refreshIntervalSeconds : 5,
                     forKey: SettingsKey.refreshIntervalSeconds.rawValue)

        defaults.set(max(0, min(100, memoryThresholdPercent)),
                     forKey: SettingsKey.memoryThresholdPercent.rawValue)
        defaults.set(max(0, min(100, cpuThresholdPercent)),
                     forKey: SettingsKey.cpuThresholdPercent.rawValue)
        defaults.set(max(0, min(100, diskThresholdPercent)),
                     forKey: SettingsKey.diskThresholdPercent.rawValue)

        defaults.set(max(1, min(10, consecutiveSamplesToTrigger)),
                     forKey: SettingsKey.consecutiveSamplesToTrigger.rawValue)
        defaults.set(max(1, min(60, alertRepeatMinutes)),
                     forKey: SettingsKey.alertRepeatMinutes.rawValue)

        defaults.set(networkProbeTarget, forKey: SettingsKey.networkProbeTarget.rawValue)
        defaults.set(httpServerEnabled, forKey: SettingsKey.httpServerEnabled.rawValue)
        defaults.set(max(1024, min(65535, httpServerPort)),
                     forKey: SettingsKey.httpServerPort.rawValue)
    }

    /// Save a specific setting
    func saveRefreshInterval() {
        let validValues = [5, 10, 30]
        defaults.set(validValues.contains(refreshIntervalSeconds) ? refreshIntervalSeconds : 5,
                     forKey: SettingsKey.refreshIntervalSeconds.rawValue)
    }

    func saveMemoryThreshold() {
        defaults.set(max(0, min(100, memoryThresholdPercent)),
                     forKey: SettingsKey.memoryThresholdPercent.rawValue)
    }

    func saveCpuThreshold() {
        defaults.set(max(0, min(100, cpuThresholdPercent)),
                     forKey: SettingsKey.cpuThresholdPercent.rawValue)
    }

    func saveDiskThreshold() {
        defaults.set(max(0, min(100, diskThresholdPercent)),
                     forKey: SettingsKey.diskThresholdPercent.rawValue)
    }

    func saveConsecutiveSamples() {
        defaults.set(max(1, min(10, consecutiveSamplesToTrigger)),
                     forKey: SettingsKey.consecutiveSamplesToTrigger.rawValue)
    }

    func saveAlertRepeatMinutes() {
        defaults.set(max(1, min(60, alertRepeatMinutes)),
                     forKey: SettingsKey.alertRepeatMinutes.rawValue)
    }

    func saveNetworkProbeTarget() {
        defaults.set(networkProbeTarget, forKey: SettingsKey.networkProbeTarget.rawValue)
    }

    func saveHttpServerEnabled() {
        defaults.set(httpServerEnabled, forKey: SettingsKey.httpServerEnabled.rawValue)
    }

    func saveHttpServerPort() {
        defaults.set(max(1024, min(65535, httpServerPort)),
                     forKey: SettingsKey.httpServerPort.rawValue)
    }
}
