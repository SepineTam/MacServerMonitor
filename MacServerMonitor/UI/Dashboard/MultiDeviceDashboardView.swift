//
//  MultiDeviceDashboardView.swift
//  MacServerMonitor
//
//  Multi-device monitoring dashboard
//

import SwiftUI

enum ViewMode: String, CaseIterable {
    case card = "Card"
    case list = "List"

    var icon: String {
        switch self {
        case .card: return "square.grid.2x2"
        case .list: return "list.bullet"
        }
    }
}

struct MultiDeviceDashboardView: View {
    @StateObject private var registry = DeviceRegistry.shared
    @StateObject private var alertEngine = AlertEngine.shared
    @State private var showingSettings = false
    @State private var showingDevices = false
    @State private var selectedDeviceId: UUID?
    @State private var viewMode: ViewMode = .card

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("MacServerMonitor")
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()

                // View mode toggle
                Picker("", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Image(systemName: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
                .help("Toggle view mode")

                Button(action: { showingDevices = true }) {
                    Image(systemName: "desktopcomputer")
                }
                .buttonStyle(.borderless)
                .help("Device Manager (⌘D)")

                Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.borderless)
                .help("Settings (⌘,)")
            }
            .padding()

            Divider()

            // Device tabs
            if registry.enabledDevices.count > 1 {
                deviceTabs
                Divider()
            }

            // Content
            ScrollView {
                if viewMode == .card {
                    cardView
                } else {
                    listView
                }
            }

            Divider()

            // Footer
            footer
        }
        .frame(minWidth: 900, minHeight: 600)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingDevices) {
            DeviceManagerView()
        }
        .onReceive(timer) { _ in
            // Trigger view refresh
        }
        .onReceive(NotificationCenter.default.publisher(for: .openDevices)) { _ in
            showingDevices = true
        }
    }

    @ViewBuilder
    private var deviceTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(registry.enabledDevices) { device in
                    Button(action: { selectedDeviceId = device.id }) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(statusColor(for: device))
                                .frame(width: 8, height: 8)

                            Text(device.name)
                                .font(.subheadline)

                            if device.status == .offline {
                                Image(systemName: "wifi.exclamationmark")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedDeviceId == device.id ? Color.accentColor.opacity(0.2) : Color.clear)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var cardView: some View {
        VStack(spacing: 20) {
            ForEach(displayedDevices, id: \.id) { device in
                if let metrics = registry.remoteMetrics[device.id] {
                    DeviceCardView(device: device, metrics: metrics)
                } else if device.status == .offline {
                    OfflineDeviceCard(device: device)
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private var listView: some View {
        VStack(spacing: 0) {
            // List header
            HStack {
                Text("Device")
                    .font(.headline)
                    .frame(width: 200, alignment: .leading)

                Text("CPU")
                    .font(.headline)
                    .frame(width: 100)

                Text("Memory")
                    .font(.headline)
                    .frame(width: 100)

                Text("Disk")
                    .font(.headline)
                    .frame(width: 100)

                Text("Network")
                    .font(.headline)
                    .frame(width: 100)

                Spacer()
            }
            .padding()
            .background(Color(.controlBackgroundColor))

            Divider()

            // List rows
            ForEach(displayedDevices, id: \.id) { device in
                if let metrics = registry.remoteMetrics[device.id] {
                    DeviceListRow(device: device, metrics: metrics)
                } else if device.status == .offline {
                    OfflineDeviceListRow(device: device)
                }
                Divider()
            }
        }
        .padding(.top)
    }

    @ViewBuilder
    private var footer: some View {
        HStack {
            if let firstDevice = displayedDevices.first,
               let metrics = registry.remoteMetrics[firstDevice.id] {
                Text("Last updated: \(metrics.snapshot.formattedTimestamp())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(registry.onlineDevices.count) devices online")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Refresh: \(SettingsStore.shared.refreshIntervalSeconds)s")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var displayedDevices: [Device] {
        if let selectedId = selectedDeviceId {
            return registry.enabledDevices.filter { $0.id == selectedId }
        }
        return registry.enabledDevices
    }

    private func statusColor(for device: Device) -> Color {
        switch device.status {
        case .online: return .green
        case .offline: return .red
        case .unknown: return .gray
        case .error: return .orange
        }
    }
}

/// Device card view
struct DeviceCardView: View {
    let device: Device
    let metrics: DeviceMetrics
    @StateObject private var alertEngine = AlertEngine.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Device header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(device.hostname)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
            }

            Divider()

            // Metrics grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MetricCardMini(
                    title: "CPU",
                    value: metrics.snapshot.cpu.usagePercent,
                    unit: "%",
                    icon: "cpu",
                    color: .blue
                )

                MetricCardMini(
                    title: "Memory",
                    value: metrics.snapshot.memory.usedPercent,
                    unit: "%",
                    icon: "memorychip",
                    color: .purple
                )

                MetricCardMini(
                    title: "Disk",
                    value: metrics.snapshot.disk.usedPercent,
                    unit: "%",
                    icon: "internaldrive",
                    color: .orange
                )

                MetricCardMini(
                    title: "Network",
                    value: metrics.snapshot.network.status == .normal ? 100 : 0,
                    unit: "%",
                    icon: "wifi",
                    color: metrics.snapshot.network.status == .normal ? .green : .red
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        )
    }
}

/// Mini metric card for grid view
struct MetricCardMini: View {
    let title: String
    let value: Double
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", value))
                        .font(.system(size: 24, weight: .bold, design: .rounded))

                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.textBackgroundColor))
        )
    }
}

/// Offline device card
struct OfflineDeviceCard: View {
    let device: Device

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(device.hostname)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "wifi.exclamationmark")
                    .foregroundStyle(.red)

                Text("Offline")
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        )
    }
}

/// Device list row
struct DeviceListRow: View {
    let device: Device
    let metrics: DeviceMetrics

    var body: some View {
        HStack {
            Text(device.name)
                .frame(width: 200, alignment: .leading)

            Text(String(format: "%.1f%%", metrics.snapshot.cpu.usagePercent))
                .frame(width: 100)

            Text(String(format: "%.1f%%", metrics.snapshot.memory.usedPercent))
                .frame(width: 100)

            Text(String(format: "%.1f%%", metrics.snapshot.disk.usedPercent))
                .frame(width: 100)

            Text(metrics.snapshot.network.status == .normal ? "Normal" : "Down")
                .foregroundStyle(metrics.snapshot.network.status == .normal ? .green : .red)
                .frame(width: 100)

            Spacer()
        }
        .padding()
        .background(Color(.textBackgroundColor))
    }
}

/// Offline device list row
struct OfflineDeviceListRow: View {
    let device: Device

    var body: some View {
        HStack {
            Text(device.name)
                .frame(width: 200, alignment: .leading)
                .foregroundStyle(.secondary)

            Text("—")
                .frame(width: 100)

            Text("—")
                .frame(width: 100)

            Text("—")
                .frame(width: 100)

            Text("Offline")
                .foregroundStyle(.red)
                .frame(width: 100)

            Spacer()
        }
        .padding()
        .background(Color(.textBackgroundColor))
    }
}

extension Color {
    static let accentColor = Color.blue
}

#Preview {
    MultiDeviceDashboardView()
}
