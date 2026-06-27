import SwiftUI
import SwiftData

struct ArchiveView: View {
    @State private var viewModel = ArchiveViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTask: DailyTask?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                ForEach(viewModel.groupedTasks, id: \.month) { group in
                    VStack(alignment: .leading, spacing: Spacing.m) {
                        Text(viewModel.monthLabel(group.month))
                            .font(.sectionTitle)
                            .foregroundStyle(Color.ink700)
                            .padding(.horizontal, Spacing.m)

                        ForEach(group.tasks) { task in
                            Button {
                                selectedTask = task
                            } label: {
                                TaskArchiveRow(
                                    task: task,
                                    postCount: viewModel.postCountByTask[task.id] ?? 0,
                                    thumbnailData: viewModel.latestPostThumbByTask[task.id]
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, Spacing.m)
                        }
                    }
                }
            }
            .padding(.vertical, Spacing.m)
        }
        .paperBackground()
        .navigationTitle(NSLocalizedString("archive.nav_title", value: "灵感档案", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedTask) { task in
            TaskDetailView(task: task)
        }
        .task {
            viewModel.load(modelContext: modelContext)
        }
    }
}

private struct TaskArchiveRow: View {
    let task: DailyTask
    let postCount: Int
    var thumbnailData: Data?

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            if let data = thumbnailData, let image = ImageDecodeCache.image(from: data) {
                Rectangle()
                    .fill(Color.paper100)
                    .frame(width: 88, height: 88)
                    .overlay {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
                    .cornerRadius(Radius.image)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.s) {
                    Image(systemName: task.type.iconName)
                        .font(.caption)
                        .foregroundStyle(Color.cinnabar)
                    Text(task.adoptedOn)
                        .font(.caption)
                        .foregroundStyle(Color.ink500)
                    Spacer()
                }

                Text(task.localizedTitle())
                    .font(.taskTitle)
                    .foregroundStyle(Color.ink900)
                    .lineLimit(2)

                HStack(spacing: Spacing.s) {
                    Text(task.proposedBy)
                        .font(.caption2)
                        .foregroundStyle(Color.ink500)
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(Color.ink300)
                    Text(String.localizedStringWithFormat(NSLocalizedString("archive.votes", value: "%d 票", comment: ""), task.voteCount))
                        .font(.caption2)
                        .foregroundStyle(Color.ink500)
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(Color.ink300)
                    Text(String.localizedStringWithFormat(NSLocalizedString("archive.post_count", value: "%d 条记录", comment: ""), postCount))
                        .font(.caption2)
                        .foregroundStyle(Color.ink500)
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(Spacing.m)
        .nearbyCard(fill: .surfaceElevated, strokeOpacity: 0.14, shadowOpacity: 0.04)
    }
}
