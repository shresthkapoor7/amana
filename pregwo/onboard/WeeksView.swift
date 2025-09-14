import SwiftUI

struct WeeksView: View {
    @AppStorage("selectedWeek") var selectedWeek: Int = 1

    var body: some View {
        NavigationView {
            VStack {
                Text("How many weeks along are you?")
                    .font(.title)
                    .padding(.top, 50)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

                Spacer()
                Picker("Weeks", selection: $selectedWeek) {
                    ForEach(1...42, id: \.self) { week in
                        Text("\(week) week\(week > 1 ? "s" : "")").tag(week)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .padding()

                Spacer()
                NavigationLink(destination: ConditionsView()) {
                    Text("Next")
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
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    WeeksView()
}