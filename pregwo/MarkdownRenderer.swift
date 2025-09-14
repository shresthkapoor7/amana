import SwiftUI
import UIKit

class MarkdownRenderer {
    @MainActor
    static func render(markdown: String, width: CGFloat = 1024) -> UIImage? {
        let markdownView = Text(markdown)
            .font(.system(size: 40, weight: .regular))
            .lineSpacing(10)
            .padding(40)
            .foregroundColor(.white)
            .background(Color.black.opacity(0.75))
            .frame(width: width)
            .multilineTextAlignment(.leading)

        let renderer = ImageRenderer(content: markdownView)
        renderer.isOpaque = false
        renderer.scale = 2.0 // Render at 2x for high quality
        return renderer.uiImage
    }
}
