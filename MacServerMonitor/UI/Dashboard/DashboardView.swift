//
//  DashboardView.swift
//  MacServerMonitor
//
//  Main monitoring dashboard
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var store = MetricStore.shared
    @StateObject private var alertEngine = AlertEngine.shared
    @State private var showingSettings = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("MacServerMonitor")
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()

                Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.borderless)
            }
            .padding()

            Divider()

            // Metrics Grid
            if let snapshot = store.latestSnapshot {
                ScrollView {
                    VStack(spacing: 20) {
                        // Memory Card with trend
                        let memoryTrend = store.getSeries(points: 20).memoryUsedPercent
                        MetricCardWithTrend(
                            title: "Memory",
                            icon: "memorychip",
                            value: snapshot.memory.usedPercent,
                            unit: "%",
                            trendData: memoryTrend,
                            isAlerting: alertEngine.getAlertStatus(for: .memory).state.isActive
                        ) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Used:")
                                    Text(formatBytes(snapshot.memory.usedBytes))
                                        .foregroundStyle(.secondary)
                                }
                                HStack {
                                    Text("Total:")
                                    Text(formatBytes(snapshot.memory.totalBytes))
                                        .foregroundStyle(.secondary)
                                }
                                if let swap = snapshot.memory.swapUsedBytes {
                                    HStack {
                                        Text("Swap:")
                                        Text(formatBytes(swap))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .font(.caption)
                        }

                        // CPU Card with trend
                        let cpuTrend = store.getSeries(points: 20).cpuUsagePercent
                        MetricCardWithTrend(
                            title: "CPU",
                            icon: "cpu",
                            value: snapshot.cpu.usagePercent,
                            unit: "%",
                            trendData: cpuTrend,
                            isAlerting: alertEngine.getAlertStatus(for: .cpu).state.isActive
                        ) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Load (1m):")
                                    Text(String(format: "%.2f", snapshot.cpu.load1))
                                        .foregroundStyle(.secondary)
                                }
                                HStack {
                                    Text("Load (5m):")
                                    Text(String(format: "%.2f", snapshot.cpu.load5))
                                        .foregroundStyle(.secondary)
                                }
                                HStack {
                                    Text("Load (15m):")
                                    Text(String(format: "%.2f", snapshot.cpu.load15))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .font(.caption)
                        }

                        // Disk Card with trend
                        let diskTrend = store.getSeries(points: 20).diskUsedPercent
                        MetricCardWithTrend(
                            title: "Disk",
                            icon: "internaldrive",
                            value: snapshot.disk.usedPercent,
                            unit: "%",
                            trendData: diskTrend,
                            isAlerting: alertEngine.getAlertStatus(for: .disk).state.isActive
                        ) {
                            EmptyView()
                        }

                        // Network Card
                        NetworkCard(
                            status: snapshot.network.status,
                            lastOkTimestamp: snapshot.network.lastOkTimestamp,
                            isAlerting: alertEngine.getAlertStatus(for: .network).state.isActive
                        )
                    }
                    .padding()
                }
            } else {
                // Loading state
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading metrics...")
                        .foregroundStyle(.secondary)
                        .padding(.top)
                    Spacer()
                }
            }

            Divider()

            // Footer
            HStack {
                Text("Last updated: \(store.latestSnapshot?.formattedTimestamp() ?? "Never")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Refresh: \(SettingsStore.shared.refreshIntervalSeconds)s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onReceive(timer) { _ in
            // Trigger view refresh
        }
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let kb = Double(bytes) / 1024
        let mb = kb / 1024
        let gb = mb / 1024

        if gb >= 1 {
            return String(format: "%.2f GB", gb)
        } else if mb >= 1 {
            return String(format: "%.2f MB", mb)
        } else {
            return String(format: "%.2f KB", kb)
        }
    }
}

/// Metric card component
struct MetricCard<Content: View>: View {
    let title: String
    let icon: String
    let value: Double
    let unit: String
    let isAlerting: Bool
    let content: Content

    init(title: String, icon: String, value: Double, unit: String, isAlerting: Bool, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.value = value
        self.unit = unit
        self.isAlerting = isAlerting
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 20) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(isAlerting ? .red : .blue)
                .frame(width: 60)

            Divider()

            // Value
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", value))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(isAlerting ? .red : .primary)

                    Text(unit)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Additional content
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isAlerting ? Color.red : Color.clear, lineWidth: 2)
        )
    }
}

/// Network card component
struct NetworkCard: View {
    let status: NetworkStatus
    let lastOkTimestamp: TimeInterval
    let isAlerting: Bool

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: status == .normal ? "wifi" : "wifi.slash")
                .font(.system(size: 40))
                .foregroundStyle(status == .normal ? .green : .red)
                .frame(width: 60)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Network")
                    .font(.headline)

                Text(status == .normal ? "Normal" : "Down")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(status == .normal ? .green : .red)
            }

            Spacer()

            if status == .down && lastOkTimestamp > 0 {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Last OK:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(formatTimestamp(lastOkTimestamp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isAlerting ? Color.red : Color.clear, lineWidth: 2)
        )
    }

    private func formatTimestamp(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

extension MetricsSnapshot {
    func formattedTimestamp() -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    DashboardView()
}
