//
//  ContentView.swift
//  pregwo
//
//  Created by Shresth Kapoor on 13/09/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = "Video"
    @StateObject private var geminiService = GeminiService()

    var body: some View {
        TabView(selection: $selectedTab) {
            CallView()
                .tabItem {
                    Label("Call", systemImage: "phone.fill")
                }
                .tag("Call")

            MainARView(geminiService: geminiService, isActive: selectedTab == "Video", selectedTab: $selectedTab)
                .tabItem {
                    Label("Video", systemImage: "video.fill")
                }
                .tag("Video")

            ChatView(messages: $geminiService.messages) { message in
                Task {
                    await geminiService.sendChatMessage(message: message)
                }
            }
            .tabItem {
                Label("Chat", systemImage: "message.fill")
            }
            .tag("Chat")

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag("Settings")
        }
        .onAppear {
            geminiService.startChat()
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = .black
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}

#Preview {
    ContentView()
}
