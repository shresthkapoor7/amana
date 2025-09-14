import SwiftUI

struct ConditionsView: View {
    @State private var selectedConditions: [String] = []
    @State private var otherCondition: String = ""
    
    let conditions = [
        "High Blood Pressure",
        "Diabetes",
        "Kidney Disease",
        "Hypothyroidism",
        "Hyperthyroidism"
    ]
    
    var body: some View {
        VStack {
            Text("Do you have any of the following conditions?")
                .font(.title)
                .padding()
            
            List(conditions, id: \.self) { condition in
                Button(action: {
                    if selectedConditions.contains(condition) {
                        selectedConditions.removeAll { $0 == condition }
                    } else {
                        selectedConditions.append(condition)
                    }
                }) {
                    HStack {
                        Text(condition)
                        if selectedConditions.contains(condition) {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            
            TextField("Other (comma separated)", text: $otherCondition)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            NavigationLink(destination: DietaryView()) {
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
            .simultaneousGesture(TapGesture().onEnded {
                saveConditions()
            })
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    func saveConditions() {
        var allConditions = selectedConditions
        if !otherCondition.isEmpty {
            let otherConditions = otherCondition.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            allConditions.append(contentsOf: otherConditions)
        }
        
        UserDefaults.standard.set(allConditions, forKey: "userConditions")
    }
}

#Preview {
    ConditionsView()
}