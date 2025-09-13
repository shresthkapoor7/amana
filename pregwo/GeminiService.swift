import SwiftUI
import GoogleGenerativeAI

@Observable
class GeminiService {
    private var generativeModel: GenerativeModel?
    var result: String?
    var inProgress = false

    init() {
        // Initialize the generative model with the API key and a model name
        // The model name is a placeholder and should be updated to a supported model
        generativeModel = GenerativeModel(name: "gemini-1.5-flash-latest", apiKey: APIKey.default)
    }

    @MainActor
    func sendImage(_ image: UIImage) async {
        guard let model = generativeModel else {
            result = "Generative model not available."
            return
        }

        inProgress = true
        defer { inProgress = false }

        do {
            let response = try await model.generateContent("what is the object in users hand", image)
            if let text = response.text {
                result = text
            } else {
                result = "No response text found."
            }
        } catch {
            result = "Error: \(error.localizedDescription)"
        }
    }

    @MainActor
    func generateResponse(for image: UIImage) async -> String {
        guard let model = generativeModel else {
            let errorText = "Generative model not available."
            self.result = errorText
            return errorText
        }

        inProgress = true
        defer { inProgress = false }

        do {
            let response = try await model.generateContent("what is the object in users hand", image)
            let resultText = response.text ?? "No response text found."
            self.result = resultText
            return resultText
        } catch {
            let errorText = "Error: \(error.localizedDescription)"
            self.result = errorText
            return errorText
        }
    }
}
