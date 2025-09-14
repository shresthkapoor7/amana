import SwiftUI

struct ChatView: View {
    @Binding var messages: [ChatMessage]
    @State private var newMessageText = ""
    var onSendMessage: ((String) -> Void)?

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(messages) { message in
                        HStack {
                            if message.isFromUser {
                                Spacer()
                                Text(message.text)
                                    .padding(10)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            } else {
                                Text(LocalizedStringKey(message.text))
                                    .padding(10)
                                    .background(Color(UIColor.systemGray5))
                                    .cornerRadius(10)
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
            }

            HStack {
                TextField("Type a message...", text: $newMessageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading)

                Button(action: {
                    if !newMessageText.isEmpty {
                        onSendMessage?(newMessageText)
                        newMessageText = ""
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                }
                .padding(.trailing)
            }
            .padding(.bottom)
        }
        .navigationTitle("Chat")
    }
}
