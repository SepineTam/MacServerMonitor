//
//  AlertHistoryView.swift
//  MacServerMonitor
//
//  Alert history viewing and management interface
//

import SwiftUI
import UniformTypeIdentifiers

enum AlertTimeRange: String, CaseIterable, Identifiable {
    case hour = "1小时"
    case day = "24小时"
    case week = "7天"
    case month = "30天"
    case all = "全部"

    var id: String { rawValue }

    var timeInterval: TimeInterval? {
        switch self {
        case .hour: return 3600
        case .day: return 86400
        case .week: return 604800
        case .month: return 2592000
        case .all: return nil
        }
    }
}

struct AlertHistoryView: View {
    @StateObject private var historyManager = AlertHistoryManager.shared
    @StateObject private var deviceRegistry = DeviceRegistry.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDevice: UUID? = nil
    @State private var selectedType: AlertType? = nil
    @State private var selectedSeverity: AlertSeverity? = nil
    @State private var selectedResolved: Bool? = nil
    @State private var selectedTimeRange: AlertTimeRange = .day
    @State private var showingExportSheet = false
    @State private var exportFormat = "csv"

    private var filteredEvents: [AlertEvent] {
        let startDate: Date?
        if let interval = selectedTimeRange.timeInterval {
            startDate = Date().addingTimeInterval(-interval)
        } else {
            startDate = nil
        }

        return historyManager.getEvents(
            deviceId: selectedDevice,
            type: selectedType,
            severity: selectedSeverity,
            resolved: selectedResolved,
            startDate: startDate,
            endDate: nil
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("告警历史")
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()

                Button("导出") {
                    showingExportSheet = true
                }
                .buttonStyle(.borderedProminent)

                Button("关闭") {
                    dismiss()
                }
            }
            .padding()

            Divider()

            // Filters
            filterSection
                .padding()

            Divider()

            // Statistics
            statisticsSection
                .padding(.horizontal)
                .padding(.top, 12)

            Divider()
                .padding(.top, 12)

            // Event list
            if filteredEvents.isEmpty {
                emptyState
            } else {
                eventList
            }
        }
        .frame(width: 900, height: 700)
        .sheet(isPresented: $showingExportSheet) {
            exportSheet
        }
    }

    @ViewBuilder
    private var filterSection: some View {
        HStack(spacing: 16) {
            // Device filter
            Picker("设备", selection: $selectedDevice) {
                Text("全部设备").tag(UUID?.none)
                ForEach(deviceRegistry.devices) { device in
                    Text(device.name).tag(device.id as UUID?)
                }
            }
            .frame(width: 150)

            // Type filter
            Picker("类型", selection: $selectedType) {
                Text("全部类型").tag(AlertType?.none)
                ForEach(AlertType.allCases, id: \.self) { type in
                    Text(typeDisplayName(type)).tag(type as AlertType?)
                }
            }
            .frame(width: 120)

            // Severity filter
            Picker("级别", selection: $selectedSeverity) {
                Text("全部级别").tag(AlertSeverity?.none)
                ForEach(AlertSeverity.allCases, id: \.self) { severity in
                    Text(severity.displayName).tag(severity as AlertSeverity?)
                }
            }
            .frame(width: 100)

            // Status filter
            Picker("状态", selection: $selectedResolved) {
                Text("全部状态").tag(Bool?.none)
                Text("活跃中").tag(false as Bool?)
                Text("已解决").tag(true as Bool?)
            }
            .frame(width: 100)

            // Time range filter
            Picker("时间范围", selection: $selectedTimeRange) {
                ForEach(AlertTimeRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .frame(width: 120)

            Spacer()
        }
    }

    @ViewBuilder
    private var statisticsSection: some View {
        HStack(spacing: 24) {
            ForEach(AlertType.allCases, id: \.self) { type in
                let count = historyManager.getStatistics(
                    timeRange: selectedTimeRange.timeInterval ?? 2592000
                )[type] ?? 0

                HStack(spacing: 8) {
                    Image(systemName: typeIcon(type))
                        .foregroundStyle(typeColor(type))

                    Text(typeDisplayName(type))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("\(count)")
                        .font(.headline)
                        .foregroundStyle(count > 0 ? .red : .secondary)
                }
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("暂无告警记录")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("当前筛选条件下没有告警事件")
                .font(.body)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var eventList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(filteredEvents) { event in
                    AlertEventRow(event: event)
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                    if event.id != filteredEvents.last?.id {
                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var exportSheet: some View {
        VStack(spacing: 20) {
            Text("导出告警历史")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 12) {
                Text("选择导出格式：")
                    .font(.headline)

                Picker("格式", selection: $exportFormat) {
                    Text("CSV").tag("csv")
                    Text("JSON").tag("json")
                }
                .pickerStyle(.segmented)
            }

            HStack {
                Button("取消") {
                    showingExportSheet = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("导出") {
                    exportHistory()
                    showingExportSheet = false
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400, height: 200)
    }

    private func typeDisplayName(_ type: AlertType) -> String {
        switch type {
        case .memory: return "内存"
        case .cpu: return "CPU"
        case .disk: return "磁盘"
        case .network: return "网络"
        }
    }

    private func typeIcon(_ type: AlertType) -> String {
        switch type {
        case .memory: return "memorychip"
        case .cpu: return "cpu"
        case .disk: return "internaldrive"
        case .network: return "wifi"
        }
    }

    private func typeColor(_ type: AlertType) -> Color {
        switch type {
        case .memory: return .purple
        case .cpu: return .blue
        case .disk: return .orange
        case .network: return .green
        }
    }

    private func exportHistory() {
        let events = filteredEvents
        let content: String?

        if exportFormat == "csv" {
            content = historyManager.exportToCSV(events: events)
        } else {
            content = historyManager.exportToJSON(events: events)
        }

        guard let exportContent = content else { return }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText, .json]
        savePanel.nameFieldStringValue = "alert_history_\(Int(Date().timeIntervalSince1970)).\(exportFormat)"
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                do {
                    try exportContent.write(to: url, atomically: true, encoding: .utf8)
                    print("[Export] Successfully exported to \(url.path)")
                } catch {
                    print("[Error] Failed to export: \(error)")
                }
            }
        }
    }
}

/// Alert event row view
struct AlertEventRow: View {
    let event: AlertEvent

    var body: some View {
        HStack(spacing: 16) {
            // Severity indicator
            Circle()
                .fill(event.severity == .critical ? Color.red : Color.orange)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 6) {
                // Device and type
                HStack(spacing: 8) {
                    Text(event.deviceName)
                        .font(.headline)

                    Text("·")
                        .foregroundStyle(.secondary)

                    Text(event.alertType.rawValue.capitalized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("·")
                        .foregroundStyle(.secondary)

                    Text(event.severity.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(event.severity == .critical ? Color.red.opacity(0.2) : Color.orange.opacity(0.2))
                        .foregroundStyle(event.severity == .critical ? .red : .orange)
                        .cornerRadius(4)
                }

                // Message
                Text(event.message)
                    .font(.body)
                    .foregroundStyle(.primary)

                // Time and status
                HStack(spacing: 12) {
                    Text(event.triggeredAt.formatted(date: .abbreviated, time: .standard))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if event.isResolved, let resolved = event.resolvedAt {
                        Text("已解决")
                            .font(.caption)
                            .foregroundStyle(.green)

                        if let duration = event.duration {
                            Text("持续 \(formatDuration(duration))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text("→ \(resolved.formatted(date: .omitted, time: .standard))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("活跃中")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Spacer()

                    // Value info
                    if event.alertType != .network {
                        Text(String(format: "%.1f%% / %.1f%%", event.value, event.threshold))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        let hours = minutes / 60
        let days = hours / 24

        if days > 0 {
            return "\(days)天\(hours % 24)小时"
        } else if hours > 0 {
            return "\(hours)小时\(minutes % 60)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
}

#Preview {
    AlertHistoryView()
}
