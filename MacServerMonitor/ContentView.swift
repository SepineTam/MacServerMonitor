//
//  ContentView.swift
//  MacServerMonitor
//
//  Created by Sepine Tam
//

import SwiftUI

struct ContentView: View {
    @State private var showingSettings = false

    var body: some View {
        VStack {
            Image(systemName: "server.rack")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("MacServerMonitor")
                .font(.largeTitle)
            Text("Dashboard - Coming Soon")
                .font(.body)
                .foregroundStyle(.secondary)
                .padding()
            Button("Settings") {
                showingSettings = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

#Preview {
    ContentView()
}
