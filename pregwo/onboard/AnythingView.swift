import SwiftUI

struct AnythingView: View {
    @AppStorage("isFirstTime") var isFirstTime: Bool = true
    @State private var additionalInfo: String = ""
    @AppStorage("additionalInfo") var storedAdditionalInfo: String = ""

    var body: some View {
        VStack {
            Text("Anything else?")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()
            
            TextField("I like to follow omniHeart diet", text: $additionalInfo)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding()
            
            Spacer()
            
            Button(action: {
                storedAdditionalInfo = additionalInfo
                isFirstTime = false
            }) {
                Text("Finish")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1)
                    )
            }
            .padding(.horizontal)
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
    }
}

#Preview {
    AnythingView()
}