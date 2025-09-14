import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedWeek") var selectedWeek: Int = 1
    @AppStorage("additionalInfo") var additionalInfo: String = ""
    @AppStorage("isFirstTime") var isFirstTime: Bool = true

    @State private var userConditions: [String] = []
    @State private var userDietaryRestrictions: [String] = []
    @State private var userAllergies: [String] = []

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Pregnancy Information")) {
                    Text("Weeks Along: \(selectedWeek)")
                }

                Section(header: Text("Health Information")) {
                    if !userConditions.isEmpty {
                        ForEach(userConditions, id: \.self) { condition in
                            Text(condition)
                        }
                    } else {
                        Text("No conditions specified.")
                    }
                }

                Section(header: Text("Dietary Restrictions")) {
                    if !userDietaryRestrictions.isEmpty {
                        ForEach(userDietaryRestrictions, id: \.self) { restriction in
                            Text(restriction)
                        }
                    } else {
                        Text("No dietary restrictions specified.")
                    }
                }

                Section(header: Text("Allergies")) {
                    if !userAllergies.isEmpty {
                        ForEach(userAllergies, id: \.self) { allergy in
                            Text(allergy)
                        }
                    } else {
                        Text("No allergies specified.")
                    }
                }

                Section(header: Text("Additional Information")) {
                    Text(additionalInfo.isEmpty ? "No additional information provided." : additionalInfo)
                }

                Section {
                    Button("Reset Onboarding") {
                        isFirstTime = true
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear(perform: loadUserData)
        }
    }

    private func loadUserData() {
        userConditions = UserDefaults.standard.stringArray(forKey: "userConditions") ?? []
        userDietaryRestrictions = UserDefaults.standard.stringArray(forKey: "userDietaryRestrictions") ?? []
        userAllergies = UserDefaults.standard.stringArray(forKey: "userAllergies") ?? []
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
