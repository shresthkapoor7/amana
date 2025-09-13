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
            FoodView()
                .tabItem {
                    Label("Food", systemImage: "fork.knife")
                }
                .tag("Food")

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
