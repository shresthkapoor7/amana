import SwiftUI

struct MainARView: View {
    @State private var geminiService = GeminiService()
    @State private var clearSignal = 0
    var isActive: Bool

    var body: some View {
        ZStack {
            ARViewContainer(geminiService: geminiService, clearSignal: clearSignal, isActive: isActive)
                .ignoresSafeArea()
        }
        .onShake {
            geminiService.result = nil
            clearSignal += 1
        }
    }
}
