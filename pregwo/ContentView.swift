//
//  ContentView.swift
//  pregwo
//
//  Created by Shresth Kapoor on 13/09/25.
//

import SwiftUI

struct ContentView: View {
    @State private var geminiService = GeminiService()
    @State private var clearSignal = 0

    var body: some View {
        ZStack {
            ARViewContainer(geminiService: geminiService, clearSignal: clearSignal)
                .ignoresSafeArea()
        }
        .onShake {
            geminiService.result = nil
            clearSignal += 1
        }
    }
}

#Preview {
    ContentView()
}
