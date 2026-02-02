//
//  AlertSilenceManager.swift
//  MacServerMonitor
//
//  Alert silence and suppression management
//

import Foundation

/// Silence duration options
enum SilenceDuration: TimeInterval, CaseIterable, Identifiable {
    case oneHour = 3600
    case fourHours = 14400
    case oneDay = 86400
    case indefinite = -1

    var id: TimeInterval { rawValue }

    var displayName: String {
        switch self {
        case .oneHour: return "1小时"
        case .fourHours: return "4小时"
        case .oneDay: return "24小时"
        case .indefinite: return "永久"
        }
    }
}

/// Silence schedule rule
struct SilenceSchedule: Codable, Identifiable, Equatable {
    let id: UUID
    var startTime: String // Format: "HH:mm"
    var endTime: String   // Format: "HH:mm"
    var weekdays: Set<Int> // 0 = Sunday, 6 = Saturday
    var isEnabled: Bool

    var isActive: Bool {
        guard isEnabled else { return false }

        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.weekday, .hour, .minute], from: now)

        guard let weekday = components.weekday,
              weekdays.contains(weekday - 1), // Convert to 0-6 format
              let hour = components.hour,
              let minute = components.minute else {
            return false
        }

        let currentMinutes = hour * 60 + minute

        // Parse start and end times
        let startComponents = startTime.split(separator: ":").compactMap { Int($0) }
        let endComponents = endTime.split(separator: ":").compactMap { Int($0) }

        guard startComponents.count == 2,
              endComponents.count == 2,
              let startHour = startComponents.first,
              let startMinute = startComponents.last,
              let endHour = endComponents.first,
              let endMinute = endComponents.last else {
            return false
        }

        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute

        // Check if current time is within the silence window
        if endMinutes > startMinutes {
            // Normal case: window doesn't cross midnight
            return currentMinutes >= startMinutes && currentMinutes < endMinutes
        } else {
            // Special case: window crosses midnight
            return currentMinutes >= startMinutes || currentMinutes < endMinutes
        }
    }
}

/// Alert silence manager
final class AlertSilenceManager: ObservableObject {
    // MARK: - Singleton
    static let shared = AlertSilenceManager()

    private init() {
        loadSilenceState()
        loadSchedules()
    }

    // MARK: - Published State
    @Published private(set) var isSilenced: Bool = false
    @Published private(set) var silenceUntil: Date?
    @Published private(set) var schedules: [SilenceSchedule] = []

    // MARK: - Private State
    private var silenceTimer: Timer?
    private let userDefaultsKeySilence = "alert_silence_state"
    private let userDefaultsKeySchedules = "alert_silence_schedules"

    // MARK: - Public Methods

    /// Check if alerts should be silenced
    func shouldSilence() -> Bool {
        // Check manual silence
        if isSilenced, let until = silenceUntil {
            if until > Date() {
                return true
            } else {
                // Silence expired
                endSilence()
            }
        }

        // Check schedules
        return schedules.contains { $0.isActive }
    }

    /// Silence alerts for a duration
    func silence(for duration: SilenceDuration) {
        let until: Date?
        switch duration {
        case .indefinite:
            until = nil
        default:
            until = Date().addingTimeInterval(duration.rawValue)
        }

        DispatchQueue.main.async {
            self.isSilenced = true
            self.silenceUntil = until
            self.saveSilenceState()
            self.setupSilenceTimer()
        }

        print("[Silence] Alerts silenced for \(duration.displayName)")
    }

    /// End silence manually
    func endSilence() {
        DispatchQueue.main.async {
            self.isSilenced = false
            self.silenceUntil = nil
            self.silenceTimer?.invalidate()
            self.silenceTimer = nil
            self.saveSilenceState()
        }

        print("[Silence] Silence ended")
    }

    /// Add a new silence schedule
    func addSchedule(_ schedule: SilenceSchedule) {
        DispatchQueue.main.async {
            self.schedules.append(schedule)
            self.saveSchedules()
        }
    }

    /// Update a silence schedule
    func updateSchedule(_ schedule: SilenceSchedule) {
        DispatchQueue.main.async {
            if let index = self.schedules.firstIndex(where: { $0.id == schedule.id }) {
                self.schedules[index] = schedule
                self.saveSchedules()
            }
        }
    }

    /// Remove a silence schedule
    func removeSchedule(id: UUID) {
        DispatchQueue.main.async {
            self.schedules.removeAll { $0.id == id }
            self.saveSchedules()
        }
    }

    /// Toggle a schedule's enabled state
    func toggleSchedule(id: UUID) {
        DispatchQueue.main.async {
            if let index = self.schedules.firstIndex(where: { $0.id == id }) {
                self.schedules[index].isEnabled.toggle()
                self.saveSchedules()
            }
        }
    }

    // MARK: - Private Methods

    private func setupSilenceTimer() {
        silenceTimer?.invalidate()

        guard let until = silenceUntil else { return }

        silenceTimer = Timer.scheduledTimer(withTimeInterval: until.timeIntervalSinceNow, repeats: false) { [weak self] _ in
            self?.endSilence()
        }
    }

    private func saveSilenceState() {
        let data: [String: Any] = [
            "isSilenced": isSilenced,
            "silenceUntil": silenceUntil?.timeIntervalSince1970 ?? 0
        ]
        UserDefaults.standard.set(data, forKey: userDefaultsKeySilence)
    }

    private func loadSilenceState() {
        guard let data = UserDefaults.standard.dictionary(forKey: userDefaultsKeySilence),
              let isSilencedVal = data["isSilenced"] as? Bool else {
            return
        }

        isSilenced = isSilencedVal

        if let timestamp = data["silenceUntil"] as? TimeInterval, timestamp > 0 {
            silenceUntil = Date(timeIntervalSince1970: timestamp)
            setupSilenceTimer()
        }

        // Auto-expire if silence period has passed
        if isSilenced, let until = silenceUntil, until <= Date() {
            endSilence()
        }
    }

    private func saveSchedules() {
        do {
            let data = try JSONEncoder().encode(schedules)
            UserDefaults.standard.set(data, forKey: userDefaultsKeySchedules)
        } catch {
            print("[Error] Failed to save silence schedules: \(error)")
        }
    }

    private func loadSchedules() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKeySchedules) else {
            // Add default schedules
            addDefaultSchedules()
            return
        }

        do {
            schedules = try JSONDecoder().decode([SilenceSchedule].self, from: data)
        } catch {
            print("[Error] Failed to load silence schedules: \(error)")
            addDefaultSchedules()
        }
    }

    private func addDefaultSchedules() {
        // No default schedules - user adds them as needed
        schedules = []
    }
}
