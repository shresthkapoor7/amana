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

            VStack {
                Spacer()

                if geminiService.inProgress {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2)
                        .padding()
                } else if let result = geminiService.result {
                    ScrollView {
                        Text(result)
                            .padding()
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
                }
            }
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
