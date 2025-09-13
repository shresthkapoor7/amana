//
//  ContentView.swift
//  pregwo
//
//  Created by Shresth Kapoor on 13/09/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = "Video"

    var body: some View {
        TabView(selection: $selectedTab) {
            CallView()
                .tabItem {
                    Label("Call", systemImage: "phone.fill")
                }
                .tag("Call")

            MainARView(isActive: selectedTab == "Video")
                .tabItem {
                    Label("Video", systemImage: "video.fill")
                }
                .tag("Video")

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag("Settings")
        }
    }
}

#Preview {
    ContentView()
}
