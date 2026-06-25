import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TodayViewModel()
    @State private var taskBank: [DailyTask] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    if let task = viewModel.todayTask {
                        TaskCardView(task: task, hasCompleted: viewModel.hasCompletedToday)
                            .padding(.horizontal, Spacing.m)
                            .padding(.top, Spacing.m)
                            .transition(.move(edge: .top).combined(with: .opacity))

                        Button {
                            viewModel.showRecord = true
                        } label: {
                            HStack {
                                Text(NSLocalizedString("today.cta.record", value: "开始记录", comment: ""))
                                Image(systemName: "arrow.right")
                            }
                            .font(.headline)
                            .foregroundStyle(Color.paper50)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.m)
                            .background(Color.cinnabar)
                            .cornerRadius(Radius.button)
                        }
                        .padding(.horizontal, Spacing.m)
                        .disabled(viewModel.hasCompletedToday)
                        .opacity(viewModel.hasCompletedToday ? 0.4 : 1.0)

                        NavigationLink(value: "archive") {
                            HStack {
                                Text(NSLocalizedString("today.cta.archive", value: "看看过去的日子", comment: ""))
                                Image(systemName: "arrow.up.right")
                            }
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                            .padding(.top, Spacing.xs)
                        }
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    }
                }
                .padding(.bottom, Spacing.xxl)
            }
            .navigationTitle("附近")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.showRecord) {
                RecordView()
            }
        }
        .paperBackground()
        .task {
            taskBank = TaskBank.loadSync()
            viewModel.load(modelContext: modelContext, taskBank: taskBank)
        }
        .onChange(of: viewModel.showRecord) { _, newValue in
            if !newValue {
                viewModel.load(modelContext: modelContext, taskBank: taskBank)
            }
        }
    }
}
