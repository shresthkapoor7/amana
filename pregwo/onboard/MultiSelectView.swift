import SwiftUI

struct MultiSelectView: View {
    var options: [String]
    @Binding var selectedOptions: [String]

    let columns = [
        GridItem(.adaptive(minimum: 120))
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        if selectedOptions.contains(option) {
                            selectedOptions.removeAll { $0 == option }
                        } else {
                            selectedOptions.append(option)
                        }
                    }) {
                        VStack {
                            Text(option)
                                .font(.headline)
                                .foregroundColor(selectedOptions.contains(option) ? .white : .primary)
                                .padding()
                                .frame(maxWidth: .infinity, minHeight: 80)
                                .background(selectedOptions.contains(option) ? Color.accentColor : Color.gray.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct MultiSelectView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var selected = ["Milk", "Eggs"]
        let options = ["Milk", "Eggs", "Peanuts", "Tree nuts", "Shellfish", "Wheat", "Soy", "Sesame"]
        var body: some View {
            MultiSelectView(options: options, selectedOptions: $selected)
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}