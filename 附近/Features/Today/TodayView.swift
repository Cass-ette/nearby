import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TodayViewModel()
    @State private var taskBank: [DailyTask] = []

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
        }
        .onChange(of: viewModel.showRecord) { _, newValue in
            if !newValue {
                viewModel.load(modelContext: modelContext, taskBank: taskBank)
            }
        }
    }
}
