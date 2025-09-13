import SwiftUI

struct CallView: View {
    @State private var isCallActive = false
    @StateObject private var cameraManager = SimpleCameraManager()
    @StateObject private var speechService = SpeechRecognitionService()
    @StateObject private var geminiService = GeminiService()
    private let ttsService = TextToSpeechService()

    var body: some View {
        VStack {
            if isCallActive {
                ZStack {
                    SimpleCameraView(cameraManager: cameraManager)
                        .ignoresSafeArea()

                    VStack {
                        // Display for spoken text
                        if let lastMessage = speechService.conversationHistory.last {
                            Text(lastMessage)
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(10)
                                .transition(.opacity)
                                .padding(.top)
                        }

                        // Display for Gemini's response
                        if let geminiResponse = geminiService.result, !geminiResponse.isEmpty {
                            Text(geminiResponse)
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue.opacity(0.7))
                                .cornerRadius(10)
                                .transition(.opacity)
                                .padding(.top)
                        }

                        Spacer()

                        // Controls at the bottom
                        HStack {
                            Spacer()

                            Button(action: {
                                speechService.conversationHistory.removeAll()
                                geminiService.result = nil
                                geminiService.endChat()
                                isCallActive = false
                            }) {
                                Image(systemName: "phone.down.fill")
                                    .padding()
                            }
                            .background(Color.red)
                            .foregroundColor(.white)
                            .clipShape( Circle() )

                            Spacer()
                        }
                        .padding(.bottom, 20)
                    }
                }
                .onAppear {
                    cameraManager.start()
                    speechService.startListening()
                    geminiService.startChat()

                    speechService.onSpeechStarted = {
                        ttsService.stop()
                    }
                }
                .onDisappear {
                    cameraManager.stop()
                    speechService.stopListening()
                    geminiService.endChat()
                }
                .onReceive(NotificationCenter.default.publisher(for: .userSaidStop)) { _ in
                    ttsService.stop()
                }
                .onChange(of: speechService.conversationHistory) {
                    guard let lastMessage = speechService.conversationHistory.last else { return }

                    cameraManager.captureFrame { image in
                        guard let image = image else { return }

                        Task {
                            let response = await geminiService.sendChatMessageWithImage(
                                for: image,
                                message: lastMessage
                            )
                            ttsService.speak(text: response)
                        }
                    }
                }
            } else {
                Button("Start a Call") {
                    isCallActive = true
                }
                .font(.title)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
}
