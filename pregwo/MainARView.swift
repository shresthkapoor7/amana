import SwiftUI

struct MainARView: View {
    @ObservedObject var geminiService: GeminiService
    @State private var clearSignal = 0
    var isActive: Bool
    @Binding var selectedTab: String

    var body: some View {
        ZStack {
            ARViewContainer(geminiService: geminiService, clearSignal: clearSignal, isActive: isActive, selectedTab: $selectedTab)
                .ignoresSafeArea()
        }
        .onShake {
            clearSignal += 1
        }
    }
}
