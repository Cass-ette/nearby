import SwiftUI
import SwiftData

struct RecordView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = RecordViewModel()
    @State private var showError: Bool = false

    private var todayTask: DailyTask {
        let bank = TaskBank.loadSync()
        return TaskDistributor.task(for: Date(), bank: bank)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    PhotoPickerButton(image: $viewModel.originalImage)

                    if viewModel.originalImage != nil {
                        FilterStrip(originalImage: viewModel.originalImage!, selected: $viewModel.selectedFilter)
                    }

                    Divider().overlay(Color.ink300)

                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text(NSLocalizedString("record.field.title", value: "标题（可选）", comment: ""))
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                        TextField(NSLocalizedString("record.title.placeholder", value: "起个名字…", comment: ""), text: $viewModel.title)
                            .font(.bodySerif)
                            .padding(Spacing.s)
                            .background(Color.paper100)
                            .cornerRadius(Radius.button)
                    }

                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text(NSLocalizedString("record.field.text", value: "记一段…", comment: ""))
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                        ZStack(alignment: .topLeading) {
                            if viewModel.text.isEmpty {
                                Text(NSLocalizedString("record.text.placeholder", value: "今天看见的、路过的、感觉到的。", comment: ""))
                                    .font(.bodySerif)
                                    .foregroundStyle(Color.ink300)
                                    .padding(.horizontal, Spacing.m)
                                    .padding(.vertical, Spacing.l)
                            }
                            TextEditor(text: $viewModel.text)
                                .font(.bodySerif)
                                .frame(minHeight: 120)
                                .padding(Spacing.s)
                                .background(Color.clear)
                                .scrollContentBackground(.hidden)
                        }
                        .background(Color.paper100)
                        .cornerRadius(Radius.button)
                    }

                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text(NSLocalizedString("record.field.mood", value: "心情", comment: ""))
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                        MoodSelector(selected: $viewModel.selectedMood)
                    }

                    if let loc = viewModel.fuzzyLocation {
                        Label(loc.label, systemImage: "mappin.circle.ellipse")
                            .font(.caption)
                            .foregroundStyle(Color.ink500)
                    }
                }
                .padding(Spacing.m)
            }
            .navigationTitle(NSLocalizedString("record.nav_title", value: "记录今日", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.cancel", value: "取消", comment: "")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("common.publish", value: "发布", comment: "")) {
                        Task {
                            if await viewModel.save(modelContext: modelContext, task: todayTask) {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canPublish || viewModel.isSaving)
                }
            }
            .alert("Error", isPresented: $showError, actions: {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            }, message: {
                Text(viewModel.errorMessage ?? "")
            })
            .onChange(of: viewModel.errorMessage) { _, newValue in
                showError = (newValue != nil)
            }
        }
        .paperBackground()
        .task {
            await viewModel.setupLocation()
        }
    }
}
