//
//  ContentView.swift
//  MacServerMonitor
//
//  Created by Sepine Tam
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MultiDeviceDashboardView()
    }
}

#Preview {
    ContentView()
}

extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
    static let openDevices = Notification.Name("openDevices")
}
