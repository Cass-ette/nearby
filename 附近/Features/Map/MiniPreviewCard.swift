import SwiftUI

struct MiniPreviewCard: View {
    let post: Post
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.m) {
                AsyncDecodedImage(data: post.displayThumbnailDataList.first) { image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.paper100
                }
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: Radius.button))
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    if let title = post.title {
                        Text(title)
                            .font(.sectionTitle)
                            .foregroundStyle(Color.ink900)
                            .lineLimit(1)
                    }
                    if !post.text.isEmpty {
                        Text(post.text)
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                            .lineLimit(2)
                    }
                    HStack(spacing: Spacing.xs) {
                        if let label = post.publicFuzzyLabel {
                            Text(label)
                                .font(.caption)
                                .foregroundStyle(Color.ink500)
                            Text("·")
                        }
                        Text(post.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.ink300)
            }
            .padding(Spacing.m)
            .background(.thinMaterial)
            .cornerRadius(Radius.card)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .stroke(Color.paper50.opacity(0.85), lineWidth: 0.8)
            )
            .shadow(color: Color.ink900.opacity(0.12), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }
}
