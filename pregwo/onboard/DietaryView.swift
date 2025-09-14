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
            
            Text("You can select multiple restrictions.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom)
            
            MultiSelectView(options: restrictions, selectedOptions: $selectedRestrictions)
            
            TextField("Other (comma separated)", text: $otherRestriction)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            NavigationLink(destination: AllergiesView()) {
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
                saveRestrictions()
            })
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
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