import SwiftUI

struct AnythingView: View {
    @AppStorage("isFirstTime") var isFirstTime: Bool = true

    var body: some View {
        VStack {
            Text("hello anything.swift")
            Button(action: {
                isFirstTime = false
            }) {
                Text("Finish")
            }
        }
    }
}

#Preview {
    AnythingView()
}