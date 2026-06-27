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
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.s), GridItem(.flexible(), spacing: Spacing.s), GridItem(.flexible(), spacing: Spacing.s)], spacing: Spacing.s) {
                                ForEach(viewModel.myPosts) { post in
                                    Button {
                                        selectedPost = post
                                    } label: {
                                        if let thumbData = post.displayThumbnailDataList.first, let thumb = ImageDecodeCache.image(from: thumbData) {
                                            Rectangle()
                                                .fill(Color.paper100)
                                                .frame(height: 120)
                                                .overlay {
                                                    Image(uiImage: thumb)
                                                        .resizable()
                                                        .scaledToFill()
                                                }
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
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, Spacing.m)
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
            if let thumbData = post.displayThumbnailDataList.first, let thumb = ImageDecodeCache.image(from: thumbData) {
                Rectangle()
                    .fill(Color.paper100)
                    .frame(width: 72, height: 72)
                    .overlay {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
                    .cornerRadius(Radius.image)
            }

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
