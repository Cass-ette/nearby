import SwiftUI

struct PaperBackground: ViewModifier {
    var color: Color = .paper50

    func body(content: Content) -> some View {
        ZStack {
            color.ignoresSafeArea()
            Canvas { context, size in
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(color))
                context.opacity = 0.04
                for _ in 0..<600 {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let r = CGFloat.random(in: 0.3...1.2)
                    context.fill(Path(CGRect(x: x, y: y, width: r, height: r)), with: .color(.black))
                }
            }
            .ignoresSafeArea()
            content
        }
    }
}

extension View {
    func paperBackground(color: Color = .paper50) -> some View {
        modifier(PaperBackground(color: color))
    }
}
