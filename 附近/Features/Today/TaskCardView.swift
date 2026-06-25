import SwiftUI

struct TaskCardView: View {
    let task: DailyTask
    var hasCompleted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(spacing: Spacing.s) {
                Image(systemName: task.type.iconName)
                    .font(.caption)
                    .foregroundStyle(Color.ink500)
                Text(NSLocalizedString("today.label", value: "今日任务", comment: ""))
                    .font(.caption)
                    .foregroundStyle(Color.ink500)
            }

            Text(task.localizedTitle())
                .font(.taskTitle)
                .foregroundStyle(Color.ink900)
                .lineSpacing(4)

            Text(task.localizedPrompt())
                .font(.bodySerif)
                .foregroundStyle(Color.ink700)
                .lineSpacing(5)

            Divider().overlay(Color.ink300)

            HStack(spacing: Spacing.s) {
                Text(task.proposedBy)
                    .font(.caption)
                    .foregroundStyle(Color.ink500)
                Text("·")
                    .font(.caption)
                    .foregroundStyle(Color.ink300)
                Text(String.localizedStringWithFormat(NSLocalizedString("today.votes", value: "%d 位邻居投票选中", comment: ""), task.voteCount))
                    .font(.caption)
                    .foregroundStyle(Color.ink500)
                Spacer()
            }

            if let refName = task.referenceImageName, let uiImage = UIImage(named: refName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
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
                .stroke(Color.ink300, lineWidth: 0.5)
        )
        .overlay(alignment: .bottomTrailing) {
            if hasCompleted {
                SealStamp()
                    .padding(Spacing.m)
            }
        }
    }
}
