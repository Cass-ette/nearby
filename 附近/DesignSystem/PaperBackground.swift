import SwiftUI

struct PaperBackground: ViewModifier {
    var color: Color = .paper50

    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [
                        color,
                        Color.paper100.opacity(0.86),
                        Color.paper200.opacity(0.28)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
    }
}

extension View {
    func paperBackground(color: Color = .paper50) -> some View {
        modifier(PaperBackground(color: color))
    }
}

struct NearbyCardStyle: ViewModifier {
    var cornerRadius: CGFloat = Radius.card
    var fill: Color = .surfaceElevated
    var strokeOpacity: Double = 0.18
    var shadowOpacity: Double = 0.05

    func body(content: Content) -> some View {
        content
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.ink300.opacity(strokeOpacity), lineWidth: 0.8)
            )
            .shadow(color: Color.ink900.opacity(shadowOpacity), radius: 12, x: 0, y: 6)
    }
}

struct NearbyPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color.paper50)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: [Color.cinnabar, Color.cinnabarDeep],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

extension View {
    func nearbyCard(
        cornerRadius: CGFloat = Radius.card,
        fill: Color = .surfaceElevated,
        strokeOpacity: Double = 0.18,
        shadowOpacity: Double = 0.05
    ) -> some View {
        modifier(
            NearbyCardStyle(
                cornerRadius: cornerRadius,
                fill: fill,
                strokeOpacity: strokeOpacity,
                shadowOpacity: shadowOpacity
            )
        )
    }

    func glassCard(cornerRadius: CGFloat = Radius.card, tint: Color = .paper100.opacity(0.34)) -> some View {
        self
            .background(.ultraThinMaterial)
            .background(tint)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.62), lineWidth: 0.8)
            )
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.42),
                                Color.white.opacity(0.08),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.screen)
                    .allowsHitTesting(false)
            }
            .shadow(color: Color.ink900.opacity(0.04), radius: 12, x: 0, y: 6)
    }
}
