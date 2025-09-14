import SwiftUI


struct CallView: View {
    @State private var isCallActive = false
    @StateObject private var cameraManager = SimpleCameraManager()
    @StateObject private var speechService = SpeechRecognitionService()
    @StateObject private var geminiService = GeminiService()
    private let ttsService = TextToSpeechService()
    @State private var subtitleText: String = ""
    @State private var isLoading: Bool = false

    var body: some View {
        VStack {
            if isCallActive {
                ZStack {
                    SimpleCameraView(cameraManager: cameraManager)
                        .ignoresSafeArea()

                    VStack {
                        Spacer()

                        if isLoading && subtitleText.isEmpty {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(10)
                        } else if !subtitleText.isEmpty {
                            Text(subtitleText)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                                .transition(.opacity.animation(.easeInOut))
                                .padding(.horizontal)
                        }

                        HStack {
                            Spacer()
                            Button(action: endCall) {
                                Image(systemName: "phone.down.fill")
                                    .padding()
                            }
                            .background(Color.red)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            Spacer()
                        }
                        .padding(.bottom, 20)
                    }
                }
                .onAppear(perform: startCall)
                .onDisappear(perform: endCall)
                .onReceive(NotificationCenter.default.publisher(for: .userSaidStop)) { _ in
                    ttsService.stop()
                }
                .onChange(of: speechService.transcription) { newTranscription in
                    if let transcription = newTranscription, !transcription.isEmpty {
                        self.subtitleText = transcription
                    }
                }
                .onChange(of: speechService.finalTranscription) { newTranscription in
                    guard let transcription = newTranscription, !transcription.isEmpty else { return }

                    cameraManager.captureFrame { image in
                        guard let image = image else { return }
                        Task {
                            self.isLoading = true
                            let response = await geminiService.sendChatMessageWithImage(for: image, message: transcription)
                            self.subtitleText = response.trimmingCharacters(in: .whitespacesAndNewlines)
                            self.isLoading = false
                            ttsService.speak(text: response)
                            speechService.clearFinalTranscription()
                            speechService.startListening()
                        }
                    }
                }
            } else {
                Button("Start a Call") {
                    isCallActive = true
                    geminiService.startChat()
                }
                .font(.title)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }

    private func startCall() {
        cameraManager.start()
        speechService.startListening()
        geminiService.startChat()

        speechService.onSpeechStarted = {
            ttsService.stop()
            speechService.unmute()
            self.subtitleText = ""
        }

        ttsService.onSpeechStarted = {
            speechService.mute()
        }

        ttsService.onSpeechFinished = {
            speechService.unmute()
            self.subtitleText = ""
        }
    }

    private func endCall() {
        cameraManager.stop()
        speechService.stopListening()
        geminiService.endChat()
        ttsService.stop()
        subtitleText = ""
        isCallActive = false
    }
}
