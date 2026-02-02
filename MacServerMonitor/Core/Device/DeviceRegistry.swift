//
//  DeviceRegistry.swift
//  MacServerMonitor
//
//  Device registry and management
//

import Foundation
import Combine

/// Device registry for managing all devices
final class DeviceRegistry: ObservableObject {
    static let shared = DeviceRegistry()

    @Published var devices: [Device] = []
    @Published var remoteMetrics: [UUID: DeviceMetrics] = [:]

    private let saveKey = "registered_devices"
    private var metricsUpdateTimer: Timer?

    private init() {
        loadDevices()
        startMetricsCollection()
    }

    // MARK: - Device Discovery Callbacks

    func discoveredDevice(hostname: String, address: String) {
        // Check if device already exists
        if let index = devices.firstIndex(where: { $0.hostname == hostname }) {
            // Update last seen and status
            devices[index].lastSeen = Date()
            devices[index].status = .online
            devices[index].address = address

            print("[DeviceRegistry] Updated device: \(hostname)")
        } else {
            // Add new device
            let device = Device(
                name: hostname,
                hostname: hostname,
                address: address,
                status: .online
            )
            devices.append(device)
            print("[DeviceRegistry] Added new device: \(hostname)")
        }

        saveDevices()
    }

    func deviceDisconnected(_ hostname: String) {
        if let index = devices.firstIndex(where: { $0.hostname == hostname }) {
            devices[index].status = .offline
            print("[DeviceRegistry] Device disconnected: \(hostname)")
        }
    }

    // MARK: - Device Management

    func addDevice(_ device: Device) {
        devices.append(device)
        saveDevices()
    }

    func removeDevice(id: UUID) {
        devices.removeAll { $0.id == id }
        remoteMetrics.removeValue(forKey: id)
        saveDevices()
    }

    func updateDevice(_ device: Device) {
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index] = device
            saveDevices()
        }
    }

    func toggleDeviceEnabled(id: UUID) {
        if let index = devices.firstIndex(where: { $0.id == id }) {
            devices[index].isEnabled.toggle()
            saveDevices()
        }
    }

    // MARK: - Persistence

    private func loadDevices() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([Device].self, from: data) else {
            // Add local device if no devices exist
            addLocalDevice()
            return
        }

        devices = decoded
    }

    private func saveDevices() {
        if let encoded = try? JSONEncoder().encode(devices) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func addLocalDevice() {
        let localInfo = LocalDeviceInfo.shared
        let localDevice = Device(
            name: localInfo.name,
            hostname: localInfo.hostname,
            address: "127.0.0.1",
            isEnabled: true,
            status: .online
        )
        devices.append(localDevice)
        saveDevices()
    }

    // MARK: - Metrics Collection

    private func startMetricsCollection() {
        // Update metrics every 5 seconds
        metricsUpdateTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.fetchAllMetrics()
        }
    }

    private func fetchAllMetrics() {
        for device in devices where device.isEnabled && device.status == .online {
            if device.isLocal {
                // Local device - use MetricStore
                if let snapshot = MetricStore.shared.latestSnapshot {
                    let metrics = DeviceMetrics(
                        deviceId: device.id,
                        deviceName: device.name,
                        hostname: device.hostname,
                        snapshot: snapshot,
                        timestamp: Date()
                    )
                    remoteMetrics[device.id] = metrics
                }
            } else {
                // Remote device - fetch via HTTP
                fetchRemoteMetrics(device: device)
            }
        }
    }

    private func fetchRemoteMetrics(device: Device) {
        let token = SettingsStore.shared.httpServerToken
        let url = URL(string: "\(device.baseURL)/api/metrics?token=\(token)")!

        var request = URLRequest(url: url)
        request.timeoutInterval = 3

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                print("[DeviceRegistry] Failed to fetch metrics from \(device.hostname): \(error)")
                DispatchQueue.main.async {
                    self.handleFetchError(device: device)
                }
                return
            }

            guard let data = data,
                  let snapshot = try? JSONDecoder().decode(MetricsSnapshot.self, from: data) else {
                DispatchQueue.main.async {
                    self.handleFetchError(device: device)
                }
                return
            }

            DispatchQueue.main.async {
                let metrics = DeviceMetrics(
                    deviceId: device.id,
                    deviceName: device.name,
                    hostname: device.hostname,
                    snapshot: snapshot,
                    timestamp: Date()
                )
                self.remoteMetrics[device.id] = metrics

                // Update device status
                if let index = self.devices.firstIndex(where: { $0.id == device.id }) {
                    self.devices[index].status = .online
                    self.devices[index].lastSeen = Date()
                }
            }
        }.resume()
    }

    private func handleFetchError(device: Device) {
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index].status = .offline
        }
    }

    // MARK: - Convenience

    var enabledDevices: [Device] {
        devices.filter { $0.isEnabled }
    }

    var onlineDevices: [Device] {
        enabledDevices.filter { $0.status == .online }
    }
}
