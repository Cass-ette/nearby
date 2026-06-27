import SwiftUI

extension Font {
    static let titleDisplay = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let taskTitle = Font.system(.title2, design: .rounded).weight(.semibold)
    static let sectionTitle = Font.system(.headline, design: .rounded).weight(.semibold)
    static let bodySerif = Font.system(.body, design: .default)
    static let bodyText = Font.system(.body, design: .default).weight(.regular)
    static let calloutText = Font.system(.callout, design: .default).weight(.regular)
    static let meta = Font.system(.caption, design: .default).weight(.medium)
    static let caption = Font.system(.caption, design: .default).weight(.regular)
}

// Helper to render Songti for Chinese, system serif for English (font fallback handled by iOS)
extension View {
    func serifTitle() -> some View {
        self.font(.taskTitle)
    }
}
