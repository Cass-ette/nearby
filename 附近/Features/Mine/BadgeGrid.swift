import SwiftUI

struct BadgeGrid: View {
    let unlocked: [Badge]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.m), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.l) {
            ForEach(Badge.allCases) { badge in
                VStack(spacing: Spacing.s) {
                    ZStack {
                        Circle()
                            .fill(unlocked.contains(badge) ? Color.cinnabar.opacity(0.15) : Color.paper100)
                            .frame(width: 72, height: 72)
                        Image(systemName: badge.iconName)
                            .font(.system(size: 26))
                            .foregroundStyle(unlocked.contains(badge) ? Color.cinnabar : Color.ink300)
                        if !unlocked.contains(badge) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.ink300)
                                .offset(x: 22, y: -22)
                        }
                    }
                    Text(badge.localizedName)
                        .font(.caption)
                        .foregroundStyle(unlocked.contains(badge) ? Color.ink900 : Color.ink500)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.horizontal, Spacing.m)
    }
}
