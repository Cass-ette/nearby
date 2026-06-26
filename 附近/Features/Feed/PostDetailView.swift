import SwiftUI
import SwiftData

struct PostDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let post: Post

    @State private var responses: [Response] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                if let image = UIImage(data: post.imageData) {
                    Rectangle()
                        .fill(Color.paper100)
                        .frame(maxWidth: .infinity)
                        .frame(height: 400)
                        .overlay {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        }
                        .clipped()
                }

                VStack(alignment: .leading, spacing: Spacing.m) {
                    if let title = post.title {
                        Text(title)
                            .font(.titleDisplay)
                            .foregroundStyle(Color.ink900)
                            .lineSpacing(3)
                    }

                    Text(post.text)
                        .font(.bodySerif)
                        .foregroundStyle(Color.ink900)
                        .lineSpacing(5)

                    HStack(spacing: Spacing.s) {
                        if let mood = post.moodTag {
                            Circle()
                                .fill(mood.color)
                                .frame(width: 8, height: 8)
                            Text(mood.localizedName)
                                .font(.caption)
                                .foregroundStyle(Color.ink500)
                        }
                        Text("·").font(.caption).foregroundStyle(Color.ink300)
                        Text(post.fuzzyLabel)
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                        Text("·").font(.caption).foregroundStyle(Color.ink300)
                        Text(post.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                    }
                    .padding(.top, Spacing.s)

                    if let task = TaskBank.loadSync().first(where: { $0.id == post.taskRef }) {
                        Divider().overlay(Color.ink300).padding(.vertical, Spacing.s)
                        Text("\(NSLocalizedString("detail.task_link", value: "任务：", comment: "")) \(task.localizedTitle())")
                            .font(.caption)
                            .foregroundStyle(Color.ink700)
                    }
                }
                .padding(.horizontal, Spacing.m)

                Divider().overlay(Color.ink300).padding(.vertical, Spacing.s)

                VStack(alignment: .leading, spacing: Spacing.m) {
                    Text(NSLocalizedString("detail.responses_title", value: "回应", comment: ""))
                        .font(.sectionTitle)
                        .foregroundStyle(Color.ink900)
                        .padding(.horizontal, Spacing.m)

                    if responses.isEmpty {
                        Text(NSLocalizedString("detail.no_responses", value: "还没有人留下回应。", comment: ""))
                            .font(.bodySerif)
                            .foregroundStyle(Color.ink500)
                            .padding(.horizontal, Spacing.m)
                    } else {
                        ForEach(responses) { response in
                            ResponseCard(response: response)
                                .padding(.horizontal, Spacing.m)
                        }
                    }
                }

                Spacer().frame(height: Spacing.xl)
            }
        }
        .paperBackground()
        .safeAreaInset(edge: .bottom) {
            ResponseComposer(postId: post.id) { _ in
                loadResponses()
            }
            .padding(Spacing.m)
            .background(Color.paper50.opacity(0.95))
        }
        .navigationTitle(NSLocalizedString("detail.nav_title", value: "记录", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadResponses()
        }
    }

    private func loadResponses() {
        let postId = post.id
        let predicate = #Predicate<Response> { $0.postId == postId }
        let descriptor = FetchDescriptor<Response>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        responses = (try? modelContext.fetch(descriptor)) ?? []
    }
}

private struct ResponseCard: View {
    let response: Response
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(response.authorName)
                    .font(.caption)
                    .foregroundStyle(Color.ink700)
                Spacer()
                Text(response.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(Color.ink300)
            }
            Text(response.text)
                .font(.bodySerif)
                .foregroundStyle(Color.ink900)
                .lineSpacing(3)
        }
        .padding(Spacing.m)
        .background(Color.paper100)
        .cornerRadius(Radius.button)
    }
}
