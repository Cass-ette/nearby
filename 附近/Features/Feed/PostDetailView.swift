import SwiftUI
import SwiftData

struct PostDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let post: Post

    @State private var isLiked = false
    @State private var selectedPhotoIndex = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                DetailPhotoPager(post: post, selectedIndex: $selectedPhotoIndex)

                VStack(alignment: .leading, spacing: Spacing.m) {
                    if let title = post.title {
                        Text(title)
                            .font(.titleDisplay)
                            .foregroundStyle(Color.ink900)
                            .lineSpacing(3)
                    }

                    if !post.text.isEmpty {
                        Text(post.text)
                            .font(.bodySerif)
                            .foregroundStyle(Color.ink900)
                            .lineSpacing(5)
                    }

                    HStack(spacing: Spacing.s) {
                        if let mood = post.moodTag {
                            Circle()
                                .fill(mood.color)
                                .frame(width: 8, height: 8)
                            Text(mood.localizedName)
                                .font(.caption)
                                .foregroundStyle(Color.ink500)
                        }
                        if let label = post.publicFuzzyLabel {
                            Text("·").font(.caption).foregroundStyle(Color.ink300)
                            Text(label)
                                .font(.caption)
                                .foregroundStyle(Color.ink500)
                        }
                        Text("·").font(.caption).foregroundStyle(Color.ink300)
                        Text(post.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                    }
                    .padding(.top, Spacing.s)

                    Button {
                        toggleLike()
                    } label: {
                        Label(
                            isLiked
                                ? NSLocalizedString("detail.liked", value: "已喜欢", comment: "")
                                : NSLocalizedString("detail.like", value: "喜欢", comment: ""),
                            systemImage: isLiked ? "heart.fill" : "heart"
                        )
                        .font(.caption)
                        .foregroundStyle(isLiked ? Color.cinnabar : Color.ink700)
                        .padding(.horizontal, Spacing.m)
                        .padding(.vertical, Spacing.s)
                        .background(Color.surfaceElevated)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.ink300.opacity(0.16), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        isLiked
                            ? NSLocalizedString("detail.unlike_accessibility", value: "取消喜欢", comment: "")
                            : NSLocalizedString("detail.like_accessibility", value: "喜欢这条记录", comment: "")
                    )
                }
                .padding(.horizontal, Spacing.m)

                Spacer().frame(height: Spacing.xl)
            }
        }
        .paperBackground()
        .navigationTitle(NSLocalizedString("detail.nav_title", value: "记录", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadLikeState()
        }
    }

    private func loadLikeState() {
        let key = PostLike.makeUniqueKey(postId: post.id, userId: CurrentUser.id)
        let predicate = #Predicate<PostLike> { $0.uniqueKey == key }
        let descriptor = FetchDescriptor<PostLike>(predicate: predicate)
        isLiked = ((try? modelContext.fetchCount(descriptor)) ?? 0) > 0
    }

    private func toggleLike() {
        let key = PostLike.makeUniqueKey(postId: post.id, userId: CurrentUser.id)
        let predicate = #Predicate<PostLike> { $0.uniqueKey == key }
        let descriptor = FetchDescriptor<PostLike>(predicate: predicate)

        do {
            if let existing = try modelContext.fetch(descriptor).first {
                modelContext.delete(existing)
                isLiked = false
            } else {
                modelContext.insert(PostLike(postId: post.id, userId: CurrentUser.id))
                isLiked = true
            }
            try modelContext.save()
        } catch {
            loadLikeState()
        }
    }

}

private struct DetailPhotoPager: View {
    let post: Post
    @Binding var selectedIndex: Int

    private var imageDataList: [Data] {
        post.displayImageDataList
    }

    var body: some View {
        if !imageDataList.isEmpty {
            TabView(selection: $selectedIndex) {
                ForEach(Array(imageDataList.enumerated()), id: \.offset) { index, imageData in
                    AsyncDecodedImage(data: imageData) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 430)
                            .clipped()
                    } placeholder: {
                        Color.paper100
                            .frame(maxWidth: .infinity)
                            .frame(height: 430)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: imageDataList.count > 1 ? .automatic : .never))
            .frame(height: 430)
            .clipShape(RoundedRectangle(cornerRadius: Radius.hero, style: .continuous))
            .padding(.horizontal, Spacing.m)
            .overlay(alignment: .topTrailing) {
                if imageDataList.count > 1 {
                    Text("\(selectedIndex + 1)/\(imageDataList.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.paper50)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.ink900.opacity(0.55))
                        .clipShape(Capsule())
                        .padding(Spacing.m)
                }
            }
        }
    }
}
