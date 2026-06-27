import SwiftUI

struct BadgeGrid: View {
    let unlocked: [Badge]

    @State private var selectedBadge: Badge?
    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.m), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.l) {
            ForEach(Badge.allCases) { badge in
                Button {
                    selectedBadge = badge
                } label: {
                    BadgeCell(badge: badge, isUnlocked: unlocked.contains(badge))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.m)
        .sheet(item: $selectedBadge) { badge in
            BadgeDetailSheet(badge: badge, isUnlocked: unlocked.contains(badge))
        }
    }
}

private struct BadgeCell: View {
    let badge: Badge
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: Spacing.s) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.cinnabar.opacity(0.15) : Color.paper100)
                    .frame(width: 72, height: 72)
                Image(systemName: badge.iconName)
                    .font(.system(size: 26))
                    .foregroundStyle(isUnlocked ? Color.cinnabar : Color.ink300)
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.ink300)
                        .offset(x: 22, y: -22)
                }
            }
            Text(badge.localizedName)
                .font(.caption)
                .foregroundStyle(isUnlocked ? Color.ink900 : Color.ink500)
                .multilineTextAlignment(.center)
        }
    }
}

private struct BadgeDetailSheet: View {
    let badge: Badge
    let isUnlocked: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Spacing.l) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.cinnabar.opacity(0.15) : Color.paper100)
                    .frame(width: 96, height: 96)
                Image(systemName: badge.iconName)
                    .font(.system(size: 40))
                    .foregroundStyle(isUnlocked ? Color.cinnabar : Color.ink300)
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.ink300)
                        .offset(x: 30, y: -30)
                }
            }
            .padding(.top, Spacing.xl)

            VStack(spacing: Spacing.s) {
                Text(badge.localizedName)
                    .font(.titleDisplay)
                    .foregroundStyle(Color.ink900)

                Text(isUnlocked
                     ? NSLocalizedString("badge.unlocked", value: "已解锁", comment: "")
                     : NSLocalizedString("badge.locked", value: "未解锁", comment: ""))
                    .font(.caption)
                    .foregroundStyle(isUnlocked ? Color.cinnabar : Color.ink500)
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.xs)
                    .background(isUnlocked ? Color.cinnabar.opacity(0.12) : Color.paper200)
                    .cornerRadius(Radius.button)

                Text(badge.criteriaDescription)
                    .font(.bodySerif)
                    .foregroundStyle(Color.ink700)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text(NSLocalizedString("common.close", value: "关闭", comment: ""))
                    .font(.headline)
                    .foregroundStyle(Color.paper50)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.m)
                    .background(Color.cinnabar)
                    .cornerRadius(Radius.button)
            }
            .padding(.horizontal, Spacing.m)
            .padding(.bottom, Spacing.l)
        }
        .paperBackground()
    }
}
