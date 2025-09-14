import SwiftUI
import UIKit

struct NutrientView: View {
    var label: String
    var value: Int
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 32, weight: .bold))
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .frame(width: geometry.size.width, height: 16)
                        .foregroundColor(Color.gray.opacity(0.5))
                    RoundedRectangle(cornerRadius: 8)
                        .frame(width: geometry.size.width * (CGFloat(value) / 100.0), height: 16)
                        .foregroundColor(color)
                }
            }
            .frame(height: 16)
        }
        .padding(.bottom, 10)
    }
}

class MarkdownRenderer {
    @MainActor
    static func render(markdown: String, nutrients: NutrientData?, width: CGFloat = 1024) -> UIImage? {
        let content = VStack(alignment: .leading, spacing: 20) {
            if !markdown.isEmpty {
                Text(markdown)
                    .font(.system(size: 40, weight: .regular))
                    .lineSpacing(10)
                    .multilineTextAlignment(.leading)

                Divider().background(Color.white)
            }

            if let nutrients = nutrients {
                VStack(alignment: .leading, spacing: 10) {
                    NutrientView(label: "Calories", value: nutrients.calories, color: .green)
                    NutrientView(label: "Protein", value: nutrients.protein, color: .cyan)
                    NutrientView(label: "Carbs", value: nutrients.carbs, color: .yellow)
                    NutrientView(label: "Fat", value: nutrients.fat, color: .orange)
                    NutrientView(label: "Vitamins & minerals", value: nutrients.vitaminsAndMinerals, color: .purple)
                    NutrientView(label: "Safety", value: nutrients.safety, color: .red)
                }
            }
        }
        .padding(40)
        .foregroundColor(.white)
        .background(Color.black.opacity(0.75))
        .frame(width: width)
        .cornerRadius(16)

        let renderer = ImageRenderer(content: content)
        renderer.isOpaque = false
        renderer.scale = 2.0 // Render at 2x for high quality
        return renderer.uiImage
    }
}
