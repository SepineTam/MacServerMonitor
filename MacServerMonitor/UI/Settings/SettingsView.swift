//
//  SettingsView.swift
//  MacServerMonitor
//
//  Settings configuration view
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = SettingsStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Appearance Section
                    GroupBox(label: Label("Appearance", systemImage: "paintbrush")) {
                        HStack {
                            Text("Theme")
                            Spacer()
                            Picker("", selection: $settings.theme) {
                                ForEach(AppTheme.allCases) { theme in
                                    Label(theme.displayName, systemImage: theme.icon)
                                        .tag(theme)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                            .onChange(of: settings.theme) { _ in
                                settings.saveTheme()
                            }
                        }
                    }

                    // Refresh Settings Section
                    GroupBox(label: Label("Refresh", systemImage: "clock")) {
                        Picker("Interval", selection: $settings.refreshIntervalSeconds) {
                            Text("5 seconds").tag(5)
                            Text("10 seconds").tag(10)
                            Text("30 seconds").tag(30)
                        }
                        .onChange(of: settings.refreshIntervalSeconds) { _ in
                            settings.saveRefreshInterval()
                        }
                    }

                    // Alert Thresholds Section
                    GroupBox(label: Label("Alert Thresholds", systemImage: "exclamationmark.triangle")) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Memory")
                                Spacer()
                                Text("\(Int(settings.memoryThresholdPercent))%")
                                    .foregroundStyle(.secondary)
                                Slider(value: $settings.memoryThresholdPercent, in: 0...100, step: 1)
                                    .frame(width: 150)
                                    .onChange(of: settings.memoryThresholdPercent) { _ in
                                        settings.saveMemoryThreshold()
                                    }
                            }

                            HStack {
                                Text("CPU")
                                Spacer()
                                Text("\(Int(settings.cpuThresholdPercent))%")
                                    .foregroundStyle(.secondary)
                                Slider(value: $settings.cpuThresholdPercent, in: 0...100, step: 1)
                                    .frame(width: 150)
                                    .onChange(of: settings.cpuThresholdPercent) { _ in
                                        settings.saveCpuThreshold()
                                    }
                            }

                            HStack {
                                Text("Disk")
                                Spacer()
                                Text("\(Int(settings.diskThresholdPercent))%")
                                    .foregroundStyle(.secondary)
                                Slider(value: $settings.diskThresholdPercent, in: 0...100, step: 1)
                                    .frame(width: 150)
                                    .onChange(of: settings.diskThresholdPercent) { _ in
                                        settings.saveDiskThreshold()
                                    }
                            }
                        }
                    }

                    // Alert Behavior Section
                    GroupBox(label: Label("Alert Behavior", systemImage: "bell")) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Consecutive samples to trigger")
                                Spacer()
                                Picker("", selection: $settings.consecutiveSamplesToTrigger) {
                                    ForEach(1...10, id: \.self) { n in
                                        Text("\(n)").tag(n)
                                    }
                                }
                                .frame(width: 60)
                                .onChange(of: settings.consecutiveSamplesToTrigger) { _ in
                                    settings.saveConsecutiveSamples()
                                }
                            }

                            HStack {
                                Text("Alert repeat interval (minutes)")
                                Spacer()
                                Picker("", selection: $settings.alertRepeatMinutes) {
                                    ForEach(1...60, id: \.self) { n in
                                        Text("\(n)").tag(n)
                                    }
                                }
                                .frame(width: 60)
                                .onChange(of: settings.alertRepeatMinutes) { _ in
                                    settings.saveAlertRepeatMinutes()
                                }
                            }
                        }
                    }

                    // Network Settings Section
                    GroupBox(label: Label("Network", systemImage: "network")) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Probe target")
                                Spacer()
                                TextField("gateway", text: $settings.networkProbeTarget)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 150)
                                    .onSubmit {
                                        settings.saveNetworkProbeTarget()
                                    }
                            }
                            Text("Use 'gateway' for default gateway, or enter a hostname/IP")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // HTTP Server Section
                    GroupBox(label: Label("HTTP Server", systemImage: "server.rack")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Enabled", isOn: $settings.httpServerEnabled)
                                .onChange(of: settings.httpServerEnabled) { _ in
                                    settings.saveHttpServerEnabled()
                                }

                            HStack {
                                Text("Port")
                                Spacer()
                                TextField("", text: Binding(
                                    get: { String(settings.httpServerPort) },
                                    set: {
                                        if let value = Int($0) {
                                            settings.httpServerPort = value
                                        }
                                    }
                                ))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                                .onSubmit {
                                    settings.saveHttpServerPort()
                                }
                            }

                            HStack {
                                Text("Token")
                                Spacer()
                                Text(settings.httpServerToken)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .frame(width: 200)
                                Button("Regenerate") {
                                    settings.regenerateToken()
                                }
                                .controlSize(.small)
                            }
                        }
                    }

                    // Reset Button
                    HStack {
                        Spacer()
                        Button("Reset to Defaults") {
                            settings.resetToDefaults()
                        }
                        .controlSize(.large)
                    }
                }
                .padding()
            }

            // Footer
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
        }
        .frame(width: 600, height: 700)
        .padding()
    }
}

#Preview {
    SettingsView()
}
