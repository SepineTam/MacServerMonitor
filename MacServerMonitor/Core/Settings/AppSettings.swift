//
//  AppSettings.swift
//  MacServerMonitor
//
//  Application settings model
//

import Foundation

/// Application settings configuration
struct AppSettings {
    // MARK: - Theme Settings
    var theme: AppTheme

    // MARK: - Refresh Settings
    var refreshIntervalSeconds: Int

    // MARK: - Alert Thresholds
    var memoryThresholdPercent: Double
    var cpuThresholdPercent: Double
    var diskThresholdPercent: Double

    // MARK: - Alert Behavior
    var consecutiveSamplesToTrigger: Int
    var alertRepeatMinutes: Int

    // MARK: - Network Settings
    var networkProbeTarget: String

    // MARK: - HTTP Server Settings
    var httpServerEnabled: Bool
    var httpServerPort: Int
    var httpServerToken: String

    // MARK: - Defaults
    static let `default` = AppSettings(
        theme: .light,
        refreshIntervalSeconds: 5,
        memoryThresholdPercent: 85.0,
        cpuThresholdPercent: 90.0,
        diskThresholdPercent: 90.0,
        consecutiveSamplesToTrigger: 2,
        alertRepeatMinutes: 3,
        networkProbeTarget: "gateway",
        httpServerEnabled: true,
        httpServerPort: 17890,
        httpServerToken: Self.generateToken()
    )

    // MARK: - Validation
    private static let validRefreshIntervals = [5, 10, 30]
    private static let minThresholdPercent: Double = 0
    private static let maxThresholdPercent: Double = 100
    private static let minConsecutiveSamples = 1
    private static let maxConsecutiveSamples = 10
    private static let minAlertRepeatMinutes = 1
    private static let maxAlertRepeatMinutes = 60
    private static let minPort = 1024
    private static let maxPort = 65535

    /// Validate refresh interval
    var isValidRefreshInterval: Bool {
        Self.validRefreshIntervals.contains(refreshIntervalSeconds)
    }

    /// Validate threshold percent
    var isValidThreshold: Bool {
        memoryThresholdPercent >= Self.minThresholdPercent &&
        memoryThresholdPercent <= Self.maxThresholdPercent &&
        cpuThresholdPercent >= Self.minThresholdPercent &&
        cpuThresholdPercent <= Self.maxThresholdPercent &&
        diskThresholdPercent >= Self.minThresholdPercent &&
        diskThresholdPercent <= Self.maxThresholdPercent
    }

    /// Validate consecutive samples
    var isValidConsecutiveSamples: Bool {
        consecutiveSamplesToTrigger >= Self.minConsecutiveSamples &&
        consecutiveSamplesToTrigger <= Self.maxConsecutiveSamples
    }

    /// Validate alert repeat minutes
    var isValidAlertRepeatMinutes: Bool {
        alertRepeatMinutes >= Self.minAlertRepeatMinutes &&
        alertRepeatMinutes <= Self.maxAlertRepeatMinutes
    }

    /// Validate port
    var isValidPort: Bool {
        httpServerPort >= Self.minPort && httpServerPort <= Self.maxPort
    }

    /// Validate token
    var isValidToken: Bool {
        !httpServerToken.isEmpty
    }

    /// Generate random token
    static func generateToken() -> String {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<32).map { _ in chars.randomElement()! })
    }
}
