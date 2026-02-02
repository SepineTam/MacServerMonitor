//
//  MacServerMonitorApp.swift
//  MacServerMonitor
//
//  Created by Sepine Tam
//

import SwiftUI

@main
struct MacServerMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(themeManager.colorScheme)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 700)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    NotificationCenter.default.post(name: .openSettings, object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            CommandMenu("Devices") {
                Button("Device Manager...") {
                    NotificationCenter.default.post(name: .openDevices, object: nil)
                }
                .keyboardShortcut("d", modifiers: .command)
            }

            CommandMenu("Alerts") {
                Button("Alert History...") {
                    NotificationCenter.default.post(name: .openAlertHistory, object: nil)
                }
                .keyboardShortcut("h", modifiers: .command)
            }
        }
    }
}

/// App delegate to handle application lifecycle
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Apply theme
        ThemeManager.shared.applyTheme(ThemeManager.shared.currentTheme)

        // Initialize sound player
        AlertEngine.shared.setSoundPlayer(SoundPlayer.shared)

        // Start sampling coordinator
        SamplingCoordinator.shared.start()

        // Start HTTP server
        HttpServer.shared.start()

        // Start device discovery
        SimpleDeviceDiscovery.shared.startDiscovery()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Stop sampling coordinator
        SamplingCoordinator.shared.stop()

        // Stop HTTP server
        HttpServer.shared.stop()
    }
}
