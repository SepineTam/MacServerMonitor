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

    var body: some Scene {
        WindowGroup {
            ContentView()
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
        }
    }
}

/// App delegate to handle application lifecycle
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize sound player
        AlertEngine.shared.setSoundPlayer(SoundPlayer.shared)

        // Start sampling coordinator
        SamplingCoordinator.shared.start()

        // Start HTTP server
        HttpServer.shared.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Stop sampling coordinator
        SamplingCoordinator.shared.stop()

        // Stop HTTP server
        HttpServer.shared.stop()
    }
}
