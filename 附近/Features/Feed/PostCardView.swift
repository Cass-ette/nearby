import SwiftUI

struct PostCardView: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(spacing: Spacing.s) {
                Text(post.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(Color.ink500)
                Text("·")
                    .font(.caption)
                    .foregroundStyle(Color.ink300)
                Text(post.fuzzyLabel)
                    .font(.caption)
                    .foregroundStyle(Color.ink500)
                if let mood = post.moodTag {
                    Circle()
                        .fill(mood.color)
                        .frame(width: 8, height: 8)
                }
                Spacer()
            }

            if let image = UIImage(data: post.imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 320)
                    .clipped()
                    .cornerRadius(Radius.image)
            }

            if let title = post.title {
                Text(title)
                    .font(.taskTitle)
                    .foregroundStyle(Color.ink900)
                    .lineSpacing(3)
            }

            Text(post.text)
                .font(.bodySerif)
                .foregroundStyle(Color.ink700)
                .lineSpacing(4)
                .lineLimit(3)

            if let task = taskFromBank(post.taskRef) {
                HStack(spacing: Spacing.xs) {
                    Rectangle()
                        .fill(Color.ink300)
                        .frame(width: 12, height: 0.5)
                    Text(NSLocalizedString("feed.task_label", value: "任务", comment: ""))
                        .font(.caption)
                        .foregroundStyle(Color.ink500)
                    Text(task.localizedTitle())
                        .font(.caption)
                        .foregroundStyle(Color.ink500)
                        .lineLimit(1)
                }
                .padding(.top, Spacing.xs)
            }
        }
        .padding(.horizontal, Spacing.m)
        .padding(.bottom, Spacing.xxl)
    }

    private func taskFromBank(_ id: String) -> DailyTask? {
        TaskBank.loadSync().first { $0.id == id }
    }
}
