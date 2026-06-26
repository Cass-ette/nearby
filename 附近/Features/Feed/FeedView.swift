import SwiftUI
import SwiftData

struct FeedView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = FeedViewModel()
    @State private var selectedPost: Post?

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.posts.isEmpty {
                    VStack(spacing: Spacing.m) {
                        Image(systemName: "leaf")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.ink300)
                        Text(NSLocalizedString("feed.empty", value: "这里还很安静。成为第一个记录的人。", comment: ""))
                            .font(.bodySerif)
                            .foregroundStyle(Color.ink500)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Spacing.xxl)
                    .padding(.horizontal, Spacing.xl)
                } else {
                    LazyVStack(alignment: .leading, spacing: Spacing.l) {
                        ForEach(viewModel.posts) { post in
                            Button {
                                selectedPost = post
                            } label: {
                                PostCardView(post: post)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, Spacing.m)
                }
            }
            .navigationTitle(NSLocalizedString("feed.nav_title", value: "附近", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.paper50, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .containerBackground(Color.paper50, for: .navigation)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Filter", selection: $viewModel.filter) {
                        ForEach(FeedViewModel.Filter.allCases) { f in
                            Text(f.localizedName).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
            }
            .navigationDestination(item: $selectedPost) { post in
                PostDetailView(post: post)
            }
        }
        .paperBackground()
        .task {
            viewModel.load(modelContext: modelContext)
        }
        .onChange(of: viewModel.filter) { _, _ in
            viewModel.load(modelContext: modelContext)
        }
    }
}
