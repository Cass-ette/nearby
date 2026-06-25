import SwiftUI

struct MiniPreviewCard: View {
    let post: Post
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.m) {
                if let thumb = UIImage(data: post.thumbnailData) {
                    Image(uiImage: thumb)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.image))
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    if let title = post.title {
                        Text(title)
                            .font(.sectionTitle)
                            .foregroundStyle(Color.ink900)
                            .lineLimit(1)
                    }
                    Text(post.text)
                        .font(.caption)
                        .foregroundStyle(Color.ink500)
                        .lineLimit(2)
                    HStack(spacing: Spacing.xs) {
                        Text(post.authorName)
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                        Text("·")
                        Text(post.fuzzyLabel)
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.ink300)
            }
            .padding(Spacing.m)
            .background(Color.paper100)
            .cornerRadius(Radius.card)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .stroke(Color.ink300, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
