//
//  DeviceManagerView.swift
//  MacServerMonitor
//
//  Device management interface
//

import SwiftUI

struct DeviceManagerView: View {
    @StateObject private var registry = DeviceRegistry.shared
    @StateObject private var settings = SettingsStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddDevice = false
    @State private var newDeviceName = ""
    @State private var newDeviceAddress = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Devices")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                Button(action: { showingAddDevice = true }) {
                    Label("Add Device", systemImage: "plus.circle.fill")
                }
                .help("Add a new device manually")
            }
            .padding(.bottom)

            // Device list
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(registry.devices) { device in
                        DeviceRow(device: device)
                    }
                }
                .padding()
            }

            // Footer
            HStack {
                Text("\(registry.onlineDevices.count) online, \(registry.devices.count - registry.onlineDevices.count) offline")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 700, height: 500)
        .sheet(isPresented: $showingAddDevice) {
            addDeviceSheet
        }
        .onAppear {
            // Start device discovery
            SimpleDeviceDiscovery.shared.startDiscovery()
        }
        .onDisappear {
            SimpleDeviceDiscovery.shared.stopDiscovery()
        }
    }

    private var addDeviceSheet: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add Device")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                Text("Device Name")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("e.g., MacBook Pro", text: $newDeviceName)
                    .textFieldStyle(.roundedBorder)

                Text("Address (hostname.local or IP)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("e.g., macbook-pro.local", text: $newDeviceAddress)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Button("Cancel") {
                    showingAddDevice = false
                    newDeviceName = ""
                    newDeviceAddress = ""
                }

                Spacer()

                Button("Add") {
                    addDevice()
                    showingAddDevice = false
                }
                .disabled(newDeviceName.isEmpty || newDeviceAddress.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400)
    }

    private func addDevice() {
        let device = Device(
            name: newDeviceName,
            hostname: newDeviceAddress,
            address: newDeviceAddress
        )
        registry.addDevice(device)
        newDeviceName = ""
        newDeviceAddress = ""
    }
}

/// Device row component
struct DeviceRow: View {
    let device: Device
    @StateObject private var registry = DeviceRegistry.shared

    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)

            // Device info
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.headline)

                Text(device.hostname)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(device.address)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Toggle
            Toggle("", isOn: Binding(
                get: { device.isEnabled },
                set: { _ in registry.toggleDeviceEnabled(id: device.id) }
            ))
            .toggleStyle(.switch)
            .help("Enable monitoring for this device")

            // Status
            Text(device.status.rawValue.uppercased())
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.2))
                .foregroundColor(statusColor)
                .cornerRadius(4)

            // Remove button
            Button(action: { registry.removeDevice(id: device.id) }) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
            .help("Remove device")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.controlBackgroundColor))
        )
    }

    private var statusColor: Color {
        switch device.status {
        case .online: return .green
        case .offline: return .red
        case .unknown: return .gray
        case .error: return .orange
        }
    }
}

#Preview {
    DeviceManagerView()
}
