import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TodayViewModel()
    @State private var taskBank: [DailyTask] = []
    @State private var autoShowRecord: Bool = {
        ProcessInfo.processInfo.arguments.contains("--show-record")
    }()
    @State private var selectedRecentPost: Post?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.l) {
                    if let task = viewModel.todayTask {
                        TaskCardView(task: task, hasCompleted: viewModel.hasCompletedToday)
                            .padding(.horizontal, Spacing.m)
                            .padding(.top, Spacing.s)
                            .transition(.move(edge: .top).combined(with: .opacity))

                        NavigationLink(value: "archive") {
                            HStack(spacing: Spacing.xs) {
                                Text(NSLocalizedString("today.cta.archive", value: "看看过去的日子", comment: ""))
                                Image(systemName: "arrow.up.right")
                            }
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                            .padding(.top, Spacing.s)
                            .padding(.bottom, Spacing.l)
                        }
                        .buttonStyle(.plain)

                        if !viewModel.recentPosts.isEmpty {
                            RecentPostsSection(posts: viewModel.recentPosts, selectedPost: $selectedRecentPost)
                        }
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    }
                }
                .padding(.bottom, Spacing.l)
            }
            .navigationTitle("附近")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.paper50, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .containerBackground(Color.paper50, for: .navigation)
            .navigationDestination(for: String.self) { value in
                if value == "archive" {
                    ArchiveView()
                }
            }
            .navigationDestination(item: $selectedRecentPost) { post in
                PostDetailView(post: post)
            }
            .safeAreaInset(edge: .bottom) {
                if viewModel.todayTask != nil {
                    Button {
                        viewModel.showRecord = true
                    } label: {
                        HStack(spacing: Spacing.s) {
                            Text(NSLocalizedString("today.cta.record", value: "开始记录", comment: ""))
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline)
                        .foregroundStyle(Color.paper50)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.m)
                        .background(viewModel.hasCompletedToday ? Color.ink300 : Color.cinnabar)
                        .cornerRadius(Radius.button)
                    }
                    .disabled(viewModel.hasCompletedToday)
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.s)
                    .background(Color.paper50.opacity(0.95))
                }
            }
            .sheet(isPresented: $viewModel.showRecord) {
                RecordView()
            }
        }
        .paperBackground()
        .task {
            taskBank = TaskBank.loadSync()
            viewModel.load(modelContext: modelContext, taskBank: taskBank)
            if autoShowRecord && !viewModel.hasCompletedToday {
                viewModel.showRecord = true
                autoShowRecord = false
            }
        }
        .onChange(of: viewModel.showRecord) { _, newValue in
            if !newValue {
                viewModel.load(modelContext: modelContext, taskBank: taskBank)
            }
        }
    }
}

private struct RecentPostsSection: View {
    let posts: [Post]
    @Binding var selectedPost: Post?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(NSLocalizedString("today.recent_posts", value: "最近邻居记录", comment: ""))
                .font(.sectionTitle)
                .foregroundStyle(Color.ink700)
                .padding(.horizontal, Spacing.m)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.m) {
                    ForEach(posts) { post in
                        Button {
                            selectedPost = post
                        } label: {
                            RecentPostThumb(post: post)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.m)
            }
        }
    }
}

private struct RecentPostThumb: View {
    let post: Post

    var body: some View {
        if let image = UIImage(data: post.thumbnailData) {
            Rectangle()
                .fill(Color.paper100)
                .frame(width: 100, height: 130)
                .overlay {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
                .cornerRadius(Radius.image)
        } else {
            Rectangle()
                .fill(Color.paper200)
                .frame(width: 100, height: 130)
                .cornerRadius(Radius.image)
        }
    }
}
