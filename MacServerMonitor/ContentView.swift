//
//  ContentView.swift
//  MacServerMonitor
//
//  Created by Sepine Tam
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "server.rack")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("MacServerMonitor")
                .font(.largeTitle)
            Text("Placeholder - Coming Soon")
                .font(.body)
                .foregroundStyle(.secondary)
                .padding()
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
