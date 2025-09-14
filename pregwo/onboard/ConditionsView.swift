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
            Text("You can select multiple conditions.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom)
            
            ScrollView {
                VStack {
                    ForEach(conditions, id: \.self) { condition in
                        Button(action: {
                            if self.selectedConditions.contains(condition) {
                                self.selectedConditions.removeAll { $0 == condition }
                            } else {
                                self.selectedConditions.append(condition)
                            }
                        }) {
                            HStack {
                                Text(condition)
                                    .foregroundColor(.primary)
                                if self.selectedConditions.contains(condition) {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding()
                            .background(self.selectedConditions.contains(condition) ? Color.accentColor : Color.gray.opacity(0.2))
                            .cornerRadius(10)
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
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
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