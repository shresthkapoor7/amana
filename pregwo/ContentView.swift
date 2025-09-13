//
//  ContentView.swift
//  pregwo
//
//  Created by Shresth Kapoor on 13/09/25.
//

import SwiftUI

extension CameraManager: ObservableObject {}

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var geminiService = GeminiService()

    var body: some View {
        ZStack {
            CameraView(cameraManager: cameraManager)
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
        .onAppear {
            cameraManager.geminiService = geminiService
        }
    }
}

#Preview {
    ContentView()
}
