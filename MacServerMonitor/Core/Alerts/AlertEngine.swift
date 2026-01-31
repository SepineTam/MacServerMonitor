//
//  AlertEngine.swift
//  MacServerMonitor
//
//  Alert evaluation and state management
//

import Foundation

/// Alert types
enum AlertType: String, CaseIterable {
    case memory = "memory"
    case cpu = "cpu"
    case disk = "disk"
    case network = "network"
}

/// Alert state model
enum AlertState: Equatable {
    case normal
    case alerting(since: TimeInterval)
    case throttled(until: TimeInterval)

    var isActive: Bool {
        switch self {
        case .normal:
            return false
        case .alerting, .throttled:
            return true
        }
    }
}

/// Alert item status
struct AlertStatus: Codable, Equatable {
    let type: AlertType
    var state: AlertState
    var consecutiveViolations: Int
    var nextSoundTime: TimeInterval?

    private enum CodingKeys: String, CodingKey {
        case type
        case state
        case consecutiveViolations
        case nextSoundTime
    }

    enum CodingError: Error {
        case cannotEncodeAlertState
    }

    init(type: AlertType) {
        self.type = type
        self.state = .normal
        self.consecutiveViolations = 0
        self.nextSoundTime = nil
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeString = try container.decode(String.self, forKey: .type)
        self.type = AlertType(rawValue: typeString) ?? .memory
        self.consecutiveViolations = try container.decode(Int.self, forKey: .consecutiveViolations)
        self.nextSoundTime = try container.decodeIfPresent(TimeInterval.self, forKey: .nextSoundTime)

        // Decode state
        let stateString = try container.decode(String.self, forKey: .state)
        if stateString.hasPrefix("alerting") {
            self.state = .alerting(since: Date().timeIntervalSince1970)
        } else if stateString.hasPrefix("throttled") {
            self.state = .throttled(until: Date().timeIntervalSince1970)
        } else {
            self.state = .normal
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(consecutiveViolations, forKey: .consecutiveViolations)
        try container.encodeIfPresent(nextSoundTime, forKey: .nextSoundTime)

        // Encode state as string
        switch state {
        case .normal:
            try container.encode("normal", forKey: .state)
        case .alerting:
            try container.encode("alerting", forKey: .state)
        case .throttled:
            try container.encode("throttled", forKey: .state)
        }
    }
}

/// Alert engine evaluates metrics and manages alert states
final class AlertEngine {
    // MARK: - Singleton
    static let shared = AlertEngine()

    private init() {
        // Initialize alert states
        resetAllAlerts()
    }

    // MARK: - State
    private var alerts: [AlertType: AlertStatus] = [:]
    private var soundPlayer: SoundPlayer?

    // MARK: - Public Methods

    /// Set the sound player
    func setSoundPlayer(_ player: SoundPlayer) {
        self.soundPlayer = player
    }

    /// Evaluate metrics and update alert states
    @MainActor
    func evaluate(snapshot: MetricsSnapshot) {
        let settings = SettingsStore.shared
        let requiredConsecutive = settings.consecutiveSamplesToTrigger

        // Evaluate memory
        evaluateMetric(
            type: .memory,
            value: snapshot.memory.usedPercent,
            threshold: settings.memoryThresholdPercent,
            requiredConsecutive: requiredConsecutive
        )

        // Evaluate CPU
        evaluateMetric(
            type: .cpu,
            value: snapshot.cpu.usagePercent,
            threshold: settings.cpuThresholdPercent,
            requiredConsecutive: requiredConsecutive
        )

        // Evaluate disk
        evaluateMetric(
            type: .disk,
            value: snapshot.disk.usedPercent,
            threshold: settings.diskThresholdPercent,
            requiredConsecutive: requiredConsecutive
        )

        // Evaluate network
        evaluateNetwork(
            status: snapshot.network.status,
            requiredConsecutive: requiredConsecutive
        )

        // Play sounds for any alerts that need it
        playAlerts()
    }

    /// Get all alert statuses
    func getAllAlertStatuses() -> [AlertStatus] {
        return Array(alerts.values)
    }

    /// Get alert status for a specific type
    func getAlertStatus(for type: AlertType) -> AlertStatus {
        return alerts[type] ?? AlertStatus(type: type)
    }

    /// Reset all alerts to normal state
    func resetAllAlerts() {
        for type in AlertType.allCases {
            alerts[type] = AlertStatus(type: type)
        }
    }

    // MARK: - Private Methods

    private func evaluateMetric(type: AlertType, value: Double, threshold: Double, requiredConsecutive: Int) {
        guard var alertStatus = alerts[type] else {
            alerts[type] = AlertStatus(type: type)
            return
        }

        let isViolating = value > threshold

        if isViolating {
            alertStatus.consecutiveViolations += 1

            if alertStatus.consecutiveViolations >= requiredConsecutive {
                // Threshold violated - trigger alert
                let now = Date().timeIntervalSince1970

                switch alertStatus.state {
                case .normal:
                    // First time entering alert state
                    alertStatus.state = .alerting(since: now)
                    alertStatus.nextSoundTime = now

                case .alerting, .throttled:
                    // Already in alert state, check if we need to throttle
                    if let nextTime = alertStatus.nextSoundTime, now >= nextTime {
                        // Time to play another sound
                        let settings = SettingsStore.shared
                        let repeatMinutes = settings.alertRepeatMinutes
                        alertStatus.nextSoundTime = now + TimeInterval(repeatMinutes * 60)
                        alertStatus.state = .throttled(until: now + TimeInterval(repeatMinutes * 60))
                    }
                }
            }
        } else {
            // Value recovered
            if alertStatus.state.isActive {
                // Recovered from alert
                alertStatus.state = .normal
            }
            alertStatus.consecutiveViolations = 0
            alertStatus.nextSoundTime = nil
        }

        alerts[type] = alertStatus
    }

    private func evaluateNetwork(status: NetworkStatus, requiredConsecutive: Int) {
        guard var alertStatus = alerts[.network] else {
            alerts[.network] = AlertStatus(type: .network)
            return
        }

        let isDown = status == .down

        if isDown {
            alertStatus.consecutiveViolations += 1

            if alertStatus.consecutiveViolations >= requiredConsecutive {
                let now = Date().timeIntervalSince1970

                switch alertStatus.state {
                case .normal:
                    alertStatus.state = .alerting(since: now)
                    alertStatus.nextSoundTime = now

                case .alerting, .throttled:
                    if let nextTime = alertStatus.nextSoundTime, now >= nextTime {
                        let settings = SettingsStore.shared
                        let repeatMinutes = settings.alertRepeatMinutes
                        alertStatus.nextSoundTime = now + TimeInterval(repeatMinutes * 60)
                        alertStatus.state = .throttled(until: now + TimeInterval(repeatMinutes * 60))
                    }
                }
            }
        } else {
            // Network recovered
            if alertStatus.state.isActive {
                alertStatus.state = .normal
            }
            alertStatus.consecutiveViolations = 0
            alertStatus.nextSoundTime = nil
        }

        alerts[.network] = alertStatus
    }

    private func playAlerts() {
        guard let soundPlayer = soundPlayer else { return }

        let now = Date().timeIntervalSince1970

        for (_, alertStatus) in alerts {
            if case .alerting = alertStatus.state {
                if let nextTime = alertStatus.nextSoundTime, now >= nextTime {
                    soundPlayer.play()
                }
            }
        }
    }
}
