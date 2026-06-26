import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let task: DailyTask

    @State private var relatedPosts: [Post] = []
    @State private var selectedPost: Post?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    HStack(spacing: Spacing.s) {
                        Image(systemName: task.type.iconName)
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                        Text(task.type.localizedName)
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                    }
                    Text(task.localizedTitle())
                        .font(.titleDisplay)
                        .foregroundStyle(Color.ink900)
                    Text(task.localizedPrompt())
                        .font(.bodySerif)
                        .foregroundStyle(Color.ink700)
                    HStack(spacing: Spacing.s) {
                        Text("\(NSLocalizedString("archive.proposed_by", value: "提议人", comment: "")) \(task.proposedBy)")
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(Color.ink300)
                        Text(String.localizedStringWithFormat(NSLocalizedString("archive.votes", value: "%d 票", comment: ""), task.voteCount))
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(Color.ink300)
                        Text("\(NSLocalizedString("archive.adopted_on", value: "采纳于", comment: "")) \(task.adoptedOn)")
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                    }
                }
                .padding(.horizontal, Spacing.m)

                Divider().overlay(Color.ink300).padding(.vertical, Spacing.s)

                if relatedPosts.isEmpty {
                    Text(NSLocalizedString("task_detail.empty", value: "还没有人记录这个任务。", comment: ""))
                        .font(.bodySerif)
                        .foregroundStyle(Color.ink500)
                        .padding(.horizontal, Spacing.m)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.s),
                                        GridItem(.flexible(), spacing: Spacing.s),
                                        GridItem(.flexible(), spacing: Spacing.s)],
                              spacing: Spacing.s) {
                        ForEach(relatedPosts) { post in
                            Button {
                                selectedPost = post
                            } label: {
                                if let thumb = UIImage(data: post.thumbnailData) {
                                    Image(uiImage: thumb)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 140)
                                        .clipped()
                                        .cornerRadius(Radius.image)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Spacing.m)
                }
            }
            .padding(.vertical, Spacing.m)
        }
        .paperBackground()
        .navigationTitle(NSLocalizedString("task_detail.nav_title", value: "任务", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedPost) { post in
            PostDetailView(post: post)
        }
        .task {
            loadPosts()
        }
    }

    private func loadPosts() {
        let taskId = task.id
        var descriptor = FetchDescriptor<Post>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        descriptor.predicate = #Predicate<Post> { $0.taskRef == taskId }
        relatedPosts = (try? modelContext.fetch(descriptor)) ?? []
    }
}
