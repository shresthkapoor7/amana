import SwiftUI

struct AnythingView: View {
    @AppStorage("isFirstTime") var isFirstTime: Bool = true
    @State private var additionalInfo: String = ""
    @AppStorage("additionalInfo") var storedAdditionalInfo: String = ""

    var body: some View {
        VStack {
            Text("Is there anything else you want us to know about your food choices?")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()

            TextField("I like to follow omniHeart diet", text: $additionalInfo)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Spacer()

            Button(action: {
                storedAdditionalInfo = additionalInfo
                isFirstTime = false
            }) {
                Text("Finish")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 220, height: 60)
                    .background(Color.blue)
                    .cornerRadius(15.0)
            }
            .padding()
        }
        .padding()
    }
}

#Preview {
    AnythingView()
}