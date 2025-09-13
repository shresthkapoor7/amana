import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
}
