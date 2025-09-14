import SwiftUI

struct AllergiesView: View {
    @State private var selectedAllergies: [String] = []
    @State private var otherAllergy: String = ""
    
    let allergies = [
        "Milk",
        "Eggs",
        "Peanuts",
        "Tree nuts",
        "Shellfish",
        "Wheat",
        "Soy",
        "Sesame"
    ]
    
    var body: some View {
        VStack {
            Text("Do you have any allergies?")
                .font(.title)
                .padding()
            
            List(allergies, id: \.self) { allergy in
                Button(action: {
                    if selectedAllergies.contains(allergy) {
                        selectedAllergies.removeAll { $0 == allergy }
                    } else {
                        selectedAllergies.append(allergy)
                    }
                }) {
                    HStack {
                        Text(allergy)
                        if selectedAllergies.contains(allergy) {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            
            TextField("Other (comma separated)", text: $otherAllergy)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            NavigationLink(destination: AnythingView()) {
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
                saveAllergies()
            })
        }
    }
    
    func saveAllergies() {
        var allAllergies = selectedAllergies
        if !otherAllergy.isEmpty {
            let otherAllergies = otherAllergy.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            allAllergies.append(contentsOf: otherAllergies)
        }
        
        UserDefaults.standard.set(allAllergies, forKey: "userAllergies")
    }
}

#Preview {
    AllergiesView()
}