import SwiftUI

struct DietaryView: View {
    @State private var selectedRestrictions: [String] = []
    @State private var otherRestriction: String = ""
    
    let restrictions = [
        "Vegetarian",
        "Vegan",
        "Gluten-free",
        "Dairy-free",
        "Nut-free",
        "Egg-free",
        "Kosher",
        "Halal"
    ]
    
    var body: some View {
        VStack {
            Text("Do you have any dietary restrictions?")
                .font(.title)
                .padding()
            
            List(restrictions, id: \.self) { restriction in
                Button(action: {
                    if selectedRestrictions.contains(restriction) {
                        selectedRestrictions.removeAll { $0 == restriction }
                    } else {
                        selectedRestrictions.append(restriction)
                    }
                }) {
                    HStack {
                        Text(restriction)
                        if selectedRestrictions.contains(restriction) {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            
            TextField("Other (comma separated)", text: $otherRestriction)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            NavigationLink(destination: AllergiesView()) {
                Text("Next")
            }
            .simultaneousGesture(TapGesture().onEnded {
                saveRestrictions()
            })
        }
    }
    
    func saveRestrictions() {
        var allRestrictions = selectedRestrictions
        if !otherRestriction.isEmpty {
            let otherRestrictions = otherRestriction.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            allRestrictions.append(contentsOf: otherRestrictions)
        }
        
        UserDefaults.standard.set(allRestrictions, forKey: "userDietaryRestrictions")
    }
}

#Preview {
    DietaryView()
}