import Speech
import AVFoundation
import Combine

extension Notification.Name {
    static let userSaidStop = Notification.Name("userSaidStop")
}

class SpeechRecognitionService: ObservableObject {
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private var pauseTimer: Timer?
    @Published var transcription: String?
    @Published var finalTranscription: String?
    var onSpeechStarted: (() -> Void)?
    private var isMuted = false

    init() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized.")
                default:
                    print("Speech recognition not authorized.")
                }
            }
        }
    }

    func mute() {
        isMuted = true
        if audioEngine.isRunning {
            audioEngine.pause()
        }
    }

    func unmute() {
        isMuted = false
        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
            } catch {
                print("audioEngine couldn't start because of an error: \(error)")
            }
        }
    }

    func startListening() {
        guard !audioEngine.isRunning else { return }

        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup error: \(error)")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }

        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] (result: SFSpeechRecognitionResult?, error: Error?) in
            guard let self = self else { return }

            if let result = result {
                let newTranscription = result.bestTranscription.formattedString

                // Check for the "stop" command
                if newTranscription.lowercased().contains("ok stop") || newTranscription.lowercased().contains("okay stop") {
                    NotificationCenter.default.post(name: .userSaidStop, object: nil)
                }

                if !newTranscription.isEmpty && self.transcription == nil {
                    self.onSpeechStarted?()
                }

                if !self.isMuted {
                    self.transcription = newTranscription
                    self.resetPauseTimer()
                }
            }

            if error != nil || result?.isFinal == true {
                self.stopListening()
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error: \(error)")
        }
    }

    func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil

        pauseTimer?.invalidate()
        pauseTimer = nil

        DispatchQueue.main.async {
            if let currentTranscription = self.transcription, !currentTranscription.isEmpty {
                self.finalTranscription = currentTranscription
                self.transcription = nil
                self.clearFinalTranscription()
            }
        }
    }

    func clearFinalTranscription() {
        finalTranscription = nil
    }
    private func resetPauseTimer() {
        pauseTimer?.invalidate()
        pauseTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            // This runs when the user has paused for 2.5 seconds
            DispatchQueue.main.async {
                if let currentTranscription = self.transcription, !currentTranscription.isEmpty {
                    self.finalTranscription = currentTranscription
                    self.transcription = nil
                }
            }
        }
    }
}
