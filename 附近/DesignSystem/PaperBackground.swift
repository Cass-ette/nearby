import SwiftUI

struct PaperBackground: ViewModifier {
    var color: Color = .paper50

    func body(content: Content) -> some View {
        content
            .background(color.ignoresSafeArea())
    }
}

extension View {
    func paperBackground(color: Color = .paper50) -> some View {
        modifier(PaperBackground(color: color))
    }
}
