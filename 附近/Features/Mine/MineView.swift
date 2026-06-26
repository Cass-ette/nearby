import SwiftUI
import SwiftData

struct MineView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MineViewModel()
    @State private var editingName = false
    @State private var tempName = ""
    @State private var selectedPost: Post?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.l) {
                    HStack(spacing: Spacing.m) {
                        Button {
                            tempName = CurrentUser.displayName
                            editingName = true
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Text(CurrentUser.displayName)
                                    .font(.titleDisplay)
                                    .foregroundStyle(Color.ink900)
                                Image(systemName: "pencil")
                                    .font(.caption)
                                    .foregroundStyle(Color.ink500)
                            }
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("\(viewModel.streak)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(Color.cinnabar)
                            Text(NSLocalizedString("mine.streak", value: "连续记录", comment: ""))
                                .font(.caption)
                                .foregroundStyle(Color.ink500)
                        }
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
                                          text: NSLocalizedString("mine.no_posts", value: "你还没有记录过附近。从今日任务开始。", comment: ""))
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.s), GridItem(.flexible(), spacing: Spacing.s), GridItem(.flexible(), spacing: Spacing.s)], spacing: Spacing.s) {
                                ForEach(viewModel.myPosts) { post in
                                    Button {
                                        selectedPost = post
                                    } label: {
                                        if let thumb = UIImage(data: post.thumbnailData) {
                                            Image(uiImage: thumb)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(height: 120)
                                                .clipped()
                                                .cornerRadius(Radius.image)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, Spacing.m)
                        }
                    case .responses:
                        if viewModel.myResponses.isEmpty {
                            EmptyStateView(systemImage: "text.bubble",
                                          text: NSLocalizedString("mine.no_responses", value: "还没有回应过别人的作品。", comment: ""))
                        } else {
                            VStack(spacing: Spacing.m) {
                                ForEach(viewModel.myResponses) { response in
                                    VStack(alignment: .leading, spacing: Spacing.xs) {
                                        Text(response.text)
                                            .font(.bodySerif)
                                            .foregroundStyle(Color.ink900)
                                            .lineLimit(3)
                                        Text(response.createdAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption2)
                                            .foregroundStyle(Color.ink300)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(Spacing.m)
                                    .background(Color.paper100)
                                    .cornerRadius(Radius.button)
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
            .alert(NSLocalizedString("mine.edit_name", value: "改个昵称", comment: ""), isPresented: $editingName) {
                TextField(NSLocalizedString("mine.name_placeholder", value: "昵称", comment: ""), text: $tempName)
                Button(NSLocalizedString("common.cancel", value: "取消", comment: ""), role: .cancel) {}
                Button(NSLocalizedString("common.save", value: "保存", comment: "")) {
                    let trimmed = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        CurrentUser.displayName = trimmed
                    }
                }
            }
        }
        .paperBackground()
        .task {
            viewModel.load(modelContext: modelContext)
        }
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
