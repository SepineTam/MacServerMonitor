//
//  AlertSilenceSettingsView.swift
//  MacServerMonitor
//
//  Alert silence configuration interface
//

import SwiftUI

struct AlertSilenceSettingsView: View {
    @StateObject private var silenceManager = AlertSilenceManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showingAddSchedule = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("告警静默设置")
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()

                Button("关闭") {
                    dismiss()
                }
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 24) {
                    // Quick silence
                    quickSilenceSection

                    Divider()

                    // Scheduled silence
                    scheduleSection
                }
                .padding()
            }
        }
        .frame(width: 600, height: 500)
        .sheet(isPresented: $showingAddSchedule) {
            ScheduleEditorView()
        }
    }

    @ViewBuilder
    private var quickSilenceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("快速静默")
                .font(.headline)

            Text("临时禁用所有告警通知")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if silenceManager.isSilenced {
                // Active silence display
                HStack {
                    Image(systemName: "bell.slash.fill")
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("告警已静默")

                        if let until = silenceManager.silenceUntil {
                            Text("直到 \(until.formatted(date: .omitted, time: .standard))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("永久静默")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Button("结束静默") {
                        silenceManager.endSilence()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            } else {
                // Silence options
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(SilenceDuration.allCases) { duration in
                        Button(action: { silenceManager.silence(for: duration) }) {
                            VStack(spacing: 8) {
                                Image(systemName: durationIcon(duration))
                                    .font(.title2)

                                Text(duration.displayName)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("定时静默")
                    .font(.headline)

                Spacer()

                Button(action: { showingAddSchedule = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("添加")
                    }
                    .font(.subheadline)
                }
            }

            Text("在特定时间段自动静默告警")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if silenceManager.schedules.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    Text("暂无定时静默规则")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("点击上方\"添加\"按钮创建定时静默规则")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
            } else {
                VStack(spacing: 8) {
                    ForEach(silenceManager.schedules) { schedule in
                        ScheduleRow(schedule: schedule)
                    }
                }
            }
        }
    }

    private func durationIcon(_ duration: SilenceDuration) -> String {
        switch duration {
        case .oneHour: return "clock"
        case .fourHours: return "clock.fill"
        case .oneDay: return "moon.fill"
        case .indefinite: return "moon.zzz.fill"
        }
    }
}

/// Schedule row view
struct ScheduleRow: View {
    let schedule: SilenceSchedule
    @StateObject private var silenceManager = AlertSilenceManager.shared

    var body: some View {
        HStack {
            Image(systemName: schedule.isEnabled ? "bell.badge.fill" : "bell.slash")
                .foregroundStyle(schedule.isEnabled ? .orange : .secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(schedule.startTime) - \(schedule.endTime)")
                    .font(.subheadline)

                Text(weekdayText(schedule.weekdays))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if schedule.isActive {
                    Text("当前生效中")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { schedule.isEnabled },
                set: { _ in silenceManager.toggleSchedule(id: schedule.id) }
            ))
            .toggleStyle(.switch)

            Button(action: { silenceManager.removeSchedule(id: schedule.id) }) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }

    private func weekdayText(_ weekdays: Set<Int>) -> String {
        let names = ["日", "一", "二", "三", "四", "五", "六"]
        let sorted = weekdays.sorted()
        if sorted.count == 7 {
            return "每天"
        } else if sorted.count == 5 && !sorted.contains(0) && !sorted.contains(6) {
            return "工作日"
        } else if sorted.count == 2 && sorted.contains(0) && sorted.contains(6) {
            return "周末"
        } else {
            return sorted.map { "周\(names[$0])" }.joined(separator: ", ")
        }
    }
}

/// Schedule editor view
struct ScheduleEditorView: View {
    @StateObject private var silenceManager = AlertSilenceManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var startTime = "22:00"
    @State private var endTime = "08:00"
    @State private var selectedWeekdays: Set<Int> = [0, 6] // Default: weekends

    var body: some View {
        VStack(spacing: 20) {
            Text("添加定时静默")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 12) {
                Text("时间范围：")
                    .font(.headline)

                HStack {
                    DatePicker("", selection: Binding(
                        get: { dateFromTimeString(startTime) ?? Date() },
                        set: { startTime = timeStringFromDate($0) }
                    ), displayedComponents: .hourAndMinute)

                    Text("至")
                        .foregroundStyle(.secondary)

                    DatePicker("", selection: Binding(
                        get: { dateFromTimeString(endTime) ?? Date() },
                        set: { endTime = timeStringFromDate($0) }
                    ), displayedComponents: .hourAndMinute)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("重复：")
                    .font(.headline)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(0..<7) { day in
                        let name = ["日", "一", "二", "三", "四", "五", "六"][day]
                        Button(action: { toggleWeekday(day) }) {
                            Text("周\(name)")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(selectedWeekdays.contains(day) ? Color.accentColor : Color(.controlBackgroundColor))
                                .foregroundStyle(selectedWeekdays.contains(day) ? .white : .primary)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("添加") {
                    addSchedule()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(selectedWeekdays.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 350)
    }

    private func toggleWeekday(_ day: Int) {
        if selectedWeekdays.contains(day) {
            selectedWeekdays.remove(day)
        } else {
            selectedWeekdays.insert(day)
        }
    }

    private func addSchedule() {
        let schedule = SilenceSchedule(
            id: UUID(),
            startTime: startTime,
            endTime: endTime,
            weekdays: selectedWeekdays,
            isEnabled: true
        )
        silenceManager.addSchedule(schedule)
    }

    private func dateFromTimeString(_ time: String) -> Date? {
        let components = time.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return nil }
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return calendar.date(bySettingHour: components[0], minute: components[1], second: 0, of: Date())
    }

    private func timeStringFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    AlertSilenceSettingsView()
}
