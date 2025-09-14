import SwiftUI

struct WeeksView: View {
    @AppStorage("selectedWeek") var selectedWeek: Int = 1

    var body: some View {
        NavigationView {
            VStack {
                Text("How many weeks along are you?")
                    .font(.title)
                    .padding()

                Picker("Weeks", selection: $selectedWeek) {
                    ForEach(1...40, id: \.self) { week in
                        Text("\(week) week\(week > 1 ? "s" : "")").tag(week)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .padding()

                NavigationLink(destination: ConditionsView()) {
                    Text("Next")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    WeeksView()
}