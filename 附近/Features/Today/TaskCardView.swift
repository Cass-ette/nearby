import SwiftUI

struct TaskCardView: View {
    let task: DailyTask
    var hasCompleted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            HStack(alignment: .top, spacing: Spacing.m) {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    HStack(spacing: Spacing.s) {
                        Image(systemName: task.type.iconName)
                            .font(.caption)
                            .foregroundStyle(Color.cinnabar)
                        Text(NSLocalizedString("today.label", value: "今日灵感", comment: ""))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.ink500)
                    }

                    Text(task.localizedTitle())
                        .font(.taskTitle)
                        .foregroundStyle(Color.ink900)
                        .lineSpacing(4)
                }

                Spacer(minLength: Spacing.s)

                if hasCompleted {
                    Label(NSLocalizedString("today.completed", value: "已记录", comment: ""), systemImage: "checkmark")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.cinnabar)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.cinnabar.opacity(0.10))
                        .clipShape(Capsule())
                }
            }

            Text(task.localizedPrompt())
                .font(.bodySerif)
                .foregroundStyle(Color.ink700)
                .lineSpacing(5)

            HStack(spacing: Spacing.s) {
                Text(task.proposedBy)
                    .font(.caption)
                    .foregroundStyle(Color.ink500)
                Text("·")
                    .font(.caption)
                    .foregroundStyle(Color.ink300)
                Text(String.localizedStringWithFormat(NSLocalizedString("today.votes", value: "%d 位邻居也想试试", comment: ""), task.voteCount))
                    .font(.caption)
                    .foregroundStyle(Color.ink500)
                Spacer()
            }

            if let refName = task.referenceImageName, let uiImage = UIImage(named: refName) {
                Rectangle()
                    .fill(Color.paper100)
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .overlay {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
                    .cornerRadius(Radius.image)
                    .overlay(Color.ink900.opacity(0.04))
            }
        }
        .padding(Spacing.l)
        .background(Color.paper100)
        .cornerRadius(Radius.card)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .stroke(Color.ink300.opacity(0.6), lineWidth: 0.5)
        )
    }
}
