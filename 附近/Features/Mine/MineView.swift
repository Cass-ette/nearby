import SwiftUI
import SwiftData

struct MineView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MineViewModel()
    @State private var editingName = false
    @State private var tempName = ""
    @State private var displayName = CurrentUser.displayName
    @State private var selectedPost: Post?
    @State private var selectedLikedPost: Post?
    @State private var postPendingDeletion: Post?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.l) {
                    MineHeaderCard(
                        displayName: displayName,
                        recordDayCount: viewModel.recordDayCount
                    ) {
                        tempName = displayName
                        editingName = true
                    }
                    .padding(.horizontal, Spacing.m)

                    Picker("Tab", selection: $viewModel.selectedTab) {
                        ForEach(MineViewModel.Tab.allCases) { tab in
                            Text(tab.localizedName).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, Spacing.m)

                    switch viewModel.selectedTab {
                    case .posts:
                        if viewModel.myPosts.isEmpty {
                            EmptyStateView(systemImage: "leaf",
                                          text: NSLocalizedString("mine.no_posts", value: "你还没有记录过附近。从今天开始。", comment: ""))
                        } else {
                            MinePhotoGrid(
                                posts: viewModel.myPosts,
                                onSelect: { post in
                                selectedPost = post
                                },
                                onDelete: { post in
                                    postPendingDeletion = post
                                }
                            )
                        }
                    case .likes:
                        if viewModel.likedPosts.isEmpty {
                            EmptyStateView(systemImage: "heart",
                                          text: NSLocalizedString("mine.no_likes", value: "还没有喜欢过别人的记录。", comment: ""))
                        } else {
                            LazyVStack(spacing: Spacing.m) {
                                ForEach(viewModel.likedPosts) { post in
                                    Button {
                                        selectedLikedPost = post
                                    } label: {
                                        LikedPostRow(post: post)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, Spacing.m)
                        }
                    case .badges:
                        BadgeGrid(unlocked: viewModel.badges)
                    }
                }
                .padding(.vertical, Spacing.m)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle(NSLocalizedString("mine.nav_title", value: "我的", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.paper50, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .containerBackground(Color.paper50, for: .navigation)
            .navigationDestination(item: $selectedPost) { post in
                PostDetailView(post: post)
            }
            .navigationDestination(item: $selectedLikedPost) { post in
                PostDetailView(post: post)
            }
            .alert("删除这条记录？", isPresented: deleteConfirmationBinding) {
                Button("取消", role: .cancel) {
                    postPendingDeletion = nil
                }
                Button("删除", role: .destructive) {
                    if let postPendingDeletion {
                        viewModel.delete(post: postPendingDeletion, modelContext: modelContext)
                    }
                    postPendingDeletion = nil
                }
            } message: {
                Text("删除后，这条记录会从时间流、地图和我的页面中移除。")
            }
            .alert(NSLocalizedString("mine.edit_name", value: "改个昵称", comment: ""), isPresented: $editingName) {
                TextField(NSLocalizedString("mine.name_placeholder", value: "昵称", comment: ""), text: $tempName)
                Button(NSLocalizedString("common.cancel", value: "取消", comment: ""), role: .cancel) {}
                Button(NSLocalizedString("common.save", value: "保存", comment: "")) {
                    let trimmed = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        CurrentUser.displayName = trimmed
                        displayName = trimmed
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .currentUserDidChange)) { _ in
                displayName = CurrentUser.displayName
            }
        }
        .paperBackground()
        .task {
            viewModel.load(modelContext: modelContext)
        }
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { postPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    postPendingDeletion = nil
                }
            }
        )
    }

}

private struct MinePhotoGrid: View {
    let posts: [Post]
    let onSelect: (Post) -> Void
    let onDelete: (Post) -> Void

    private let columns = 3

    var body: some View {
        GeometryReader { proxy in
            let horizontalPadding = Spacing.m
            let gap = Spacing.s
            let availableWidth = max(0, proxy.size.width - horizontalPadding * 2)
            let itemSide = floor((availableWidth - gap * CGFloat(columns - 1)) / CGFloat(columns))
            let gridColumns = Array(
                repeating: GridItem(.fixed(itemSide), spacing: gap),
                count: columns
            )

            LazyVGrid(columns: gridColumns, spacing: gap) {
                ForEach(posts) { post in
                    Button {
                        onSelect(post)
                    } label: {
                        MinePhotoTile(post: post, side: itemSide)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            onDelete(post)
                        } label: {
                            Label("删除记录", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, horizontalPadding)
            .frame(width: proxy.size.width, alignment: .center)
        }
        .frame(height: gridHeight(for: posts.count, containerWidth: UIScreen.main.bounds.width))
    }

    private func gridHeight(for count: Int, containerWidth: CGFloat) -> CGFloat {
        guard count > 0 else { return 0 }
        let horizontalPadding = Spacing.m
        let gap = Spacing.s
        let availableWidth = max(0, containerWidth - horizontalPadding * 2)
        let itemSide = floor((availableWidth - gap * CGFloat(columns - 1)) / CGFloat(columns))
        let rowCount = Int(ceil(Double(count) / Double(columns)))
        return itemSide * CGFloat(rowCount) + gap * CGFloat(max(0, rowCount - 1))
    }
}

private struct MinePhotoTile: View {
    let post: Post
    let side: CGFloat

    var body: some View {
        AsyncDecodedImage(data: post.displayThumbnailDataList.first) { image in
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } placeholder: {
            Color.paper100
        }
        .frame(width: side, height: side)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: Radius.image, style: .continuous))
        .overlay(alignment: .topTrailing) {
            if post.photoCount > 1 {
                Image(systemName: "rectangle.stack.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.paper50)
                    .padding(5)
                    .background(Color.ink900.opacity(0.5))
                    .clipShape(Circle())
                    .padding(4)
            }
        }
    }
}

private struct MineHeaderCard: View {
    let displayName: String
    let recordDayCount: Int
    let onEditName: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            HStack(alignment: .center, spacing: Spacing.m) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(displayName)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.ink900)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Button(action: onEditName) {
                        Label("编辑名称", systemImage: "pencil")
                            .font(.callout.weight(.medium))
                            .foregroundStyle(Color.ink500)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.paper50.opacity(0.72))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.ink300.opacity(0.16), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: Spacing.s)

                RecordDaysPill(count: recordDayCount)
            }
        }
        .padding(Spacing.l)
        .glassCard(cornerRadius: Radius.hero)
    }
}

private struct RecordDaysPill: View {
    let count: Int

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color.cinnabar)
                .monospacedDigit()
            Text("记录天数")
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.ink500)
        }
        .frame(width: 94, height: 86)
        .background(
            LinearGradient(
                colors: [Color.cinnabar.opacity(0.12), Color.paper100.opacity(0.74)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.62), lineWidth: 0.8)
        )
    }
}

private struct LikedPostRow: View {
    let post: Post

    var body: some View {
        HStack(spacing: Spacing.m) {
            AsyncDecodedImage(data: post.displayThumbnailDataList.first) { image in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.paper100
            }
            .frame(width: 72, height: 72)
            .clipped()
            .cornerRadius(Radius.image)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(post.title ?? (post.text.isEmpty ? NSLocalizedString("post.photo_only", value: "一张照片记录", comment: "") : post.text))
                    .font(.bodySerif)
                    .foregroundStyle(Color.ink900)
                    .lineLimit(2)
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.cinnabar)
                    Text(post.fuzzyLabel)
                        .font(.caption2)
                        .foregroundStyle(Color.ink500)
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(Color.ink300)
                    Text(post.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(Color.ink500)
                }
            }

            Spacer()
        }
        .padding(Spacing.m)
        .nearbyCard(fill: .surfaceElevated, strokeOpacity: 0.14, shadowOpacity: 0.035)
    }
}

private struct EmptyStateView: View {
    let systemImage: String
    let text: String
    var body: some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: systemImage)
                .font(.system(size: 32))
                .foregroundStyle(Color.ink300)
            Text(text)
                .font(.bodySerif)
                .foregroundStyle(Color.ink500)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }
}
