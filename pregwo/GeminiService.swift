import SwiftUI
import GoogleGenerativeAI
import Combine

class GeminiService: ObservableObject {
    private var generativeModel: GenerativeModel?
    private var chat: Chat?
    @Published var result: String?
    @Published var inProgress = false
    @Published var messages: [ChatMessage] = []

    init() {
        generativeModel = GenerativeModel(name: "gemini-1.5-flash-latest", apiKey: APIKey.default)
        startChat()
    }

    func startChat() {
        self.chat = generativeModel?.startChat(history: [
            ModelContent(role: "user", parts: [
                .text("You are an AI assistant. Format your responses in markdown.")
            ]),
            ModelContent(role: "model", parts: [
                .text("OK, I will format all my responses in markdown.")
            ])
        ])
    }

    func endChat() {
        self.chat = nil
    }

    func clearMessages() {
        messages = []
    }

    @MainActor
    func generateIsolatedResponse(for image: UIImage, conversation: [String]) async -> String {
        guard let model = generativeModel else {
            let errorText = "Generative model not available."
            self.result = errorText
            return errorText
        }

        inProgress = true
        defer { inProgress = false }

        let prompt = conversation.joined(separator: "\n")

        do {
            let response = try await model.generateContent(prompt, image)
            let resultText = response.text ?? "No response text found."
            self.result = resultText
            return resultText
        } catch {
            let errorText = "Error: \(error.localizedDescription)"
            self.result = errorText
            return errorText
        }
    }

    @MainActor
    func sendChatMessageWithImage(for image: UIImage, message: String) async -> String {
        guard let chat = self.chat else {
            let errorText = "Chat session not started."
            self.result = errorText
            return errorText
        }

        inProgress = true
        defer { inProgress = false }

        let systemInstruction = "You are on a video call. The user is showing you things through their camera. Respond to their questions naturally and conversationally. Do not refer to what you see as 'the image' or 'the picture'."
        let fullMessage = "\(systemInstruction)\n\nUser: \(message)"

        do {
            let response = try await chat.sendMessage(fullMessage, image)
            let resultText = response.text ?? "No response text found."
            self.result = resultText
            return resultText
        } catch {
            let errorText = "Error: \(error.localizedDescription)"
            self.result = errorText
            return errorText
        }
    }

    @MainActor
    func sendChatMessage(message: String) async {
        guard let chat = self.chat else {
            let errorText = "Chat session not started."
            let errorMessage = ChatMessage(text: errorText, isFromUser: false)
            self.messages.append(errorMessage)
            return
        }

        inProgress = true
        defer { inProgress = false }

        let userMessage = ChatMessage(text: message, isFromUser: true)
        self.messages.append(userMessage)

        do {
            let response = try await chat.sendMessage(message)
            let resultText = response.text ?? "No response text found."
            let modelMessage = ChatMessage(text: resultText, isFromUser: false)
            self.messages.append(modelMessage)
        } catch {
            let errorText = "Error: \(error.localizedDescription)"
            let errorMessage = ChatMessage(text: errorText, isFromUser: false)
            self.messages.append(errorMessage)
        }
    }
}
