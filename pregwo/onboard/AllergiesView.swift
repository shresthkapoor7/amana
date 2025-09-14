import SwiftUI

struct AllergiesView: View {
    var body: some View {
        VStack {
            Text("hello allergies.swift")
            NavigationLink(destination: AnythingView()) {
                Text("Next")
            }
        }
    }
}

#Preview {
    AllergiesView()
}