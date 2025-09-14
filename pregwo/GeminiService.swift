import SwiftUI
import GoogleGenerativeAI
import Combine

struct NutrientData: Codable {
    let description: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let vitaminsAndMinerals: Int
    let safety: Int
}

class GeminiService: ObservableObject {
    private var generativeModel: GenerativeModel?
    private var chat: Chat?
    @Published var result: String?
    @Published var inProgress = false
    @Published var messages: [ChatMessage] = []

    init() {
        generativeModel = GenerativeModel(name: "gemini-1.5-flash-latest", apiKey: APIKey.default)
    }

    func startChat() {
        let initialPrompt = generateInitialPrompt()
        self.chat = generativeModel?.startChat(history: [
            ModelContent(role: "user", parts: [
                .text(initialPrompt)
            ]),
            ModelContent(role: "model", parts: [
                .text("OK, I will format all my responses in markdown and act as a helpful nurse for a pregnant woman with the provided details.")
            ])
        ])
    }

    private func generateInitialPrompt() -> String {
        let userDetails = getUserDetailsPrompt()
        var prompt = "You are an AI nurse. Format your responses in markdown.\n"
        prompt += userDetails
        prompt += "\nKeep this information in mind and provide helpful, safe, and relevant advice for her pregnancy."
        return prompt
    }

    private func getUserDetailsPrompt() -> String {
        let selectedWeek = UserDefaults.standard.integer(forKey: "selectedWeek")
        let userConditions = UserDefaults.standard.stringArray(forKey: "userConditions") ?? []
        let userDietaryRestrictions = UserDefaults.standard.stringArray(forKey: "userDietaryRestrictions") ?? []
        let userAllergies = UserDefaults.standard.stringArray(forKey: "userAllergies") ?? []
        let additionalInfo = UserDefaults.standard.string(forKey: "additionalInfo") ?? ""

        var details = "The user is a pregnant woman. Here are her details:\n"
        if selectedWeek > 0 {
            details += "- Pregnancy Week: \(selectedWeek)\n"
        }
        if !userConditions.isEmpty {
            details += "- Health Conditions: \(userConditions.joined(separator: ", "))\n"
        }
        if !userDietaryRestrictions.isEmpty {
            details += "- Dietary Restrictions: \(userDietaryRestrictions.joined(separator: ", "))\n"
        }
        if !userAllergies.isEmpty {
            details += "- Allergies: \(userAllergies.joined(separator: ", "))\n"
        }
        if !additionalInfo.isEmpty {
            details += "- Additional Information: \(additionalInfo)\n"
        }
        return details
    }

    func endChat() {
        self.chat = nil
    }

    func clearMessages() {
        messages = []
    }

    @MainActor
    func generateIsolatedResponse(for image: UIImage, conversation: [String]) async -> (String, NutrientData?) {
        guard let model = generativeModel else {
            let errorText = "Generative model not available."
            self.result = errorText
            return (errorText, nil)
        }

        inProgress = true
        defer { inProgress = false }

        let userDetails = getUserDetailsPrompt()
        let jsonPrompt = """
        In your response, include a JSON object with the following structure, populated with estimated nutritional values for the object in the image. The values should be integers between 0 and 100 representing a percentage of daily recommended intake or a safety score. Also include a brief description.

        ```json
        {
          "description": "A brief summary of the food item.",
          "calories": 80,
          "protein": 20,
          "carbs": 5,
          "fat": 15,
          "vitaminsAndMinerals": 90,
          "safety": 95
        }
        ```
        """
        let fullConversation = conversation + [userDetails, jsonPrompt]
        let prompt = fullConversation.joined(separator: "\n\n")

        do {
            let response = try await model.generateContent(prompt, image)
            let resultText = response.text ?? "No response text found."

            let cleanedText = cleanTextFromJSON(from: resultText)
            self.result = cleanedText

            let nutrientData = parseNutrientData(from: resultText)
            return (cleanedText, nutrientData)
        } catch {
            let errorText = "Error: \(error.localizedDescription)"
            self.result = errorText
            return (errorText, nil)
        }
    }

    private func cleanTextFromJSON(from text: String) -> String {
        let pattern = "```json\\n([\\s\\S]*?)\\n```"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseNutrientData(from text: String) -> NutrientData? {
        guard let jsonString = extractJsonString(from: text) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let data = jsonString.data(using: .utf8),
              let nutrientData = try? decoder.decode(NutrientData.self, from: data) else {
            return nil
        }
        return nutrientData
    }

    private func extractJsonString(from text: String) -> String? {
        let pattern = "```json\\n([\\s\\S]*?)\\n```"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }

        if let jsonRange = Range(match.range(at: 1), in: text) {
            return String(text[jsonRange])
        }
        return nil
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
