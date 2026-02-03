//
//  DeviceDiscovery.swift
//  MacServerMonitor
//
//  Simple device discovery using network scanning
//

import Foundation

/// Simple device discovery service
final class SimpleDeviceDiscovery: ObservableObject {
    static let shared = SimpleDeviceDiscovery()

    private var timer: Timer?

    private init() {}

    func startDiscovery() {
        // Use common local network addresses to discover devices
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.scanLocalNetwork()
        }

        // Initial scan
        scanLocalNetwork()
    }

    func stopDiscovery() {
        timer?.invalidate()
        timer = nil
    }

    private func scanLocalNetwork() {
        // Get common hostnames from .local domain
        let commonPrefixes = [
            "macbook", "macbook-pro", "macbook-air",
            "imac", "mac-mini", "mac-studio",
            "macpro"
        ]

        for prefix in commonPrefixes {
            let hostname = "\(prefix).local"
            checkDevice(hostname: hostname)
        }
    }

    private func checkDevice(hostname: String) {
        let port = 17890
        let url = URL(string: "http://\(hostname):\(port)/api/metrics")!

        var request = URLRequest(url: url)
        request.timeoutInterval = 2

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard self != nil else { return }

            if error == nil,
               let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {

                DispatchQueue.main.async {
                    DeviceRegistry.shared.discoveredDevice(
                        hostname: hostname.replacingOccurrences(of: ".local", with: ""),
                        address: hostname
                    )
                }
            }
        }.resume()
    }
}
