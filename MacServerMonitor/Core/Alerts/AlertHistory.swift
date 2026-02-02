//
//  AlertHistory.swift
//  MacServerMonitor
//
//  Alert event history recording and management
//

import Foundation

/// Alert severity levels
enum AlertSeverity: String, Codable, CaseIterable {
    case warning = "warning"
    case critical = "critical"

    var displayName: String {
        switch self {
        case .warning: return "警告"
        case .critical: return "严重"
        }
    }

    var color: String {
        switch self {
        case .warning: return "orange"
        case .critical: return "red"
        }
    }
}

/// Alert event record
struct AlertEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let deviceId: UUID
    let deviceName: String
    let alertType: AlertType
    let severity: AlertSeverity
    let message: String
    let value: Double
    let threshold: Double
    let triggeredAt: Date
    let resolvedAt: Date?

    var isResolved: Bool {
        resolvedAt != nil
    }

    var duration: TimeInterval? {
        guard let resolved = resolvedAt else { return nil }
        return resolved.timeIntervalSince(triggeredAt)
    }

    static func == (lhs: AlertEvent, rhs: AlertEvent) -> Bool {
        lhs.id == rhs.id
    }
}

/// Alert history manager
final class AlertHistoryManager: ObservableObject {
    // MARK: - Singleton
    static let shared = AlertHistoryManager()

    private init() {
        loadEvents()
        cleanupOldEvents()
    }

    // MARK: - Published State
    @Published private(set) var events: [AlertEvent] = []

    // MARK: - Constants
    private let maxEvents = 1000
    private let retentionDays = 30
    private let userDefaultsKey = "alert_history_events"

    // MARK: - Public Methods

    /// Record a new alert event
    func recordAlert(
        deviceId: UUID,
        deviceName: String,
        type: AlertType,
        value: Double,
        threshold: Double
    ) {
        let severity = determineSeverity(type: type, value: value, threshold: threshold)

        let event = AlertEvent(
            id: UUID(),
            deviceId: deviceId,
            deviceName: deviceName,
            alertType: type,
            severity: severity,
            message: generateMessage(type: type, value: value, threshold: threshold),
            value: value,
            threshold: threshold,
            triggeredAt: Date(),
            resolvedAt: nil
        )

        DispatchQueue.main.async {
            self.events.insert(event, at: 0)
            self.saveEvents()
            self.limitEventCount()
        }
    }

    /// Resolve an alert event
    func resolveAlert(eventId: UUID) {
        DispatchQueue.main.async {
            if let index = self.events.firstIndex(where: { $0.id == eventId }) {
                let event = self.events[index]
                self.events[index] = AlertEvent(
                    id: event.id,
                    deviceId: event.deviceId,
                    deviceName: event.deviceName,
                    alertType: event.alertType,
                    severity: event.severity,
                    message: event.message,
                    value: event.value,
                    threshold: event.threshold,
                    triggeredAt: event.triggeredAt,
                    resolvedAt: Date()
                )
                self.saveEvents()
            }
        }
    }

    /// Resolve alerts by device and type
    func resolveAlerts(deviceId: UUID, type: AlertType) {
        DispatchQueue.main.async {
            let now = Date()
            for index in self.events.indices {
                let event = self.events[index]
                if event.deviceId == deviceId &&
                   event.alertType == type &&
                   event.resolvedAt == nil {
                    self.events[index] = AlertEvent(
                        id: event.id,
                        deviceId: event.deviceId,
                        deviceName: event.deviceName,
                        alertType: event.alertType,
                        severity: event.severity,
                        message: event.message,
                        value: event.value,
                        threshold: event.threshold,
                        triggeredAt: event.triggeredAt,
                        resolvedAt: now
                    )
                }
            }
            self.saveEvents()
        }
    }

    /// Get filtered events
    func getEvents(
        deviceId: UUID? = nil,
        type: AlertType? = nil,
        severity: AlertSeverity? = nil,
        resolved: Bool? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> [AlertEvent] {
        return events.filter { event in
            if let deviceId = deviceId, event.deviceId != deviceId { return false }
            if let type = type, event.alertType != type { return false }
            if let severity = severity, event.severity != severity { return false }
            if let resolved = resolved, event.isResolved != resolved { return false }
            if let start = startDate, event.triggeredAt < start { return false }
            if let end = endDate, event.triggeredAt > end { return false }
            return true
        }
    }

    /// Get alert statistics
    func getStatistics(timeRange: TimeInterval = 86400) -> [AlertType: Int] {
        let cutoffDate = Date().addingTimeInterval(-timeRange)
        var stats: [AlertType: Int] = [:]

        for type in AlertType.allCases {
            stats[type] = events.filter { $0.alertType == type && $0.triggeredAt > cutoffDate }.count
        }

        return stats
    }

    /// Export events to CSV
    func exportToCSV(events: [AlertEvent]) -> String {
        var lines: [String] = []

        // Header
        lines.append("Time,Device,Type,Severity,Message,Value,Threshold,Status,Duration")

        // Data rows
        let formatter = ISO8601DateFormatter()
        for event in events {
            let time = formatter.string(from: event.triggeredAt)
            let device = event.deviceName.replacingOccurrences(of: ",", with: ";")
            let type = event.alertType.rawValue.capitalized
            let severity = event.severity.displayName
            let message = event.message.replacingOccurrences(of: ",", with: ";")
            let value = String(format: "%.1f", event.value)
            let threshold = String(format: "%.1f", event.threshold)
            let status = event.isResolved ? "Resolved" : "Active"

            var duration = ""
            if let d = event.duration {
                duration = String(format: "%.0f", d)
            }

            let line = "\(time),\(device),\(type),\(severity),\(message),\(value),\(threshold),\(status),\(duration)"
            lines.append(line)
        }

        return lines.joined(separator: "\n")
    }

    /// Export events to JSON
    func exportToJSON(events: [AlertEvent]) -> String? {
        do {
            let data = try JSONEncoder().encode(events)
            return String(data: data, encoding: .utf8)
        } catch {
            print("[Error] Failed to encode events: \(error)")
            return nil
        }
    }

    /// Clear all events
    func clearAllEvents() {
        DispatchQueue.main.async {
            self.events.removeAll()
            self.saveEvents()
        }
    }

    // MARK: - Private Methods

    private func determineSeverity(type: AlertType, value: Double, threshold: Double) -> AlertSeverity {
        let overThreshold = value - threshold

        switch type {
        case .memory, .cpu:
            return overThreshold > 20 ? .critical : .warning
        case .disk:
            return overThreshold > 10 ? .critical : .warning
        case .network:
            return .critical
        }
    }

    private func generateMessage(type: AlertType, value: Double, threshold: Double) -> String {
        switch type {
        case .memory:
            return String(format: "内存使用率 %.1f%% 超过阈值 %.1f%%", value, threshold)
        case .cpu:
            return String(format: "CPU 使用率 %.1f%% 超过阈值 %.1f%%", value, threshold)
        case .disk:
            return String(format: "磁盘使用率 %.1f%% 超过阈值 %.1f%%", value, threshold)
        case .network:
            return "网络连接中断"
        }
    }

    private func saveEvents() {
        do {
            let data = try JSONEncoder().encode(events)
            let string = String(data: data, encoding: .utf8) ?? ""
            UserDefaults.standard.set(string, forKey: userDefaultsKey)
        } catch {
            print("[Error] Failed to save alert history: \(error)")
        }
    }

    private func loadEvents() {
        guard let string = UserDefaults.standard.string(forKey: userDefaultsKey),
              let data = string.data(using: .utf8) else {
            return
        }

        do {
            events = try JSONDecoder().decode([AlertEvent].self, from: data)
        } catch {
            print("[Error] Failed to load alert history: \(error)")
            events = []
        }
    }

    private func limitEventCount() {
        if events.count > maxEvents {
            events = Array(events.prefix(maxEvents))
            saveEvents()
        }
    }

    private func cleanupOldEvents() {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()

        DispatchQueue.main.async {
            self.events = self.events.filter { $0.triggeredAt > cutoffDate }
            self.saveEvents()
        }
    }
}
