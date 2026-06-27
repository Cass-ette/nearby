import SwiftUI
import SwiftData

struct RecordView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = RecordViewModel()
    @State private var showError: Bool = false
    @FocusState private var focusedField: RecordField?

    private enum RecordField {
        case title
        case text
    }

    private var todayTask: DailyTask {
        let bank = TaskBank.loadSync()
        return TaskDistributor.task(for: Date(), bank: bank)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(NSLocalizedString("record.header.title", value: "留下这一刻", comment: ""))
                            .font(.titleDisplay)
                            .foregroundStyle(Color.ink900)
                    }
                    .padding(.horizontal, Spacing.s)

                    RecordSection {
                        PhotoPickerButton(images: $viewModel.originalImages)

                        if let firstImage = viewModel.originalImages.first {
                            FilterStrip(originalImage: firstImage, selected: $viewModel.selectedFilter)
                                .padding(.top, Spacing.s)
                        }
                    }

                    RecordSection {
                        SectionLabel(NSLocalizedString("record.section.words", value: "写几句话", comment: ""))

                        TextField(NSLocalizedString("record.title.placeholder", value: "标题", comment: ""), text: $viewModel.title)
                            .font(.bodySerif)
                            .padding(.horizontal, Spacing.m)
                            .padding(.vertical, 14)
                            .background(Color.paper50.opacity(0.78))
                            .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                                    .stroke(Color.ink300.opacity(0.16), lineWidth: 0.8)
                            )
                            .focused($focusedField, equals: .title)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .text
                            }

                        ZStack(alignment: .topLeading) {
                            if viewModel.text.isEmpty {
                                Text(NSLocalizedString("record.text.placeholder", value: "正文（可选）", comment: ""))
                                    .font(.bodySerif)
                                    .foregroundStyle(Color.ink300)
                                    .padding(.horizontal, Spacing.m)
                                    .padding(.vertical, Spacing.l)
                            }
                            TextEditor(text: $viewModel.text)
                                .font(.bodySerif)
                                .frame(minHeight: 150)
                                .padding(Spacing.s)
                                .background(Color.clear)
                                .scrollContentBackground(.hidden)
                                .focused($focusedField, equals: .text)
                        }
                        .background(Color.paper50.opacity(0.78))
                        .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                                .stroke(Color.ink300.opacity(0.16), lineWidth: 0.8)
                        )
                    }

                    RecordSection {
                        SectionLabel(NSLocalizedString("record.field.mood", value: "心情", comment: ""))
                        MoodSelector(selected: $viewModel.selectedMood)
                    }

                    PrivacySection(viewModel: viewModel)
                }
                .padding(Spacing.m)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(NSLocalizedString("record.nav_title", value: "写一条记录", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.cancel", value: "取消", comment: "")) {
                        focusedField = nil
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("common.publish", value: "发布", comment: "")) {
                        focusedField = nil
                        Task {
                            if await viewModel.save(modelContext: modelContext, task: todayTask) {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canPublish || viewModel.isSaving)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(NSLocalizedString("common.done", value: "完成", comment: "")) {
                        focusedField = nil
                    }
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
            .onChange(of: viewModel.isPublic) { _, isPublic in
                if !isPublic {
                    viewModel.showsLocation = false
                }
            }
        }
        .paperBackground()
        .task {
            await viewModel.setupLocation()
        }
    }
}

private struct RecordSection<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            content
        }
        .padding(Spacing.l)
        .nearbyCard(fill: .surfaceElevated, strokeOpacity: 0.14, shadowOpacity: 0.035)
    }
}

private struct SectionLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.ink500)
    }
}

private struct PrivacySection: View {
    @Bindable var viewModel: RecordViewModel

    var body: some View {
        RecordSection {
            SectionLabel(NSLocalizedString("record.section.visibility", value: "谁可以看见", comment: ""))

            PrivacyChoiceRow(
                isOn: $viewModel.isPublic,
                icon: viewModel.isPublic ? "eye" : "lock",
                title: NSLocalizedString("record.public.toggle", value: "公开这条记录", comment: ""),
                detail: nil
            )

            if viewModel.isPublic, let loc = viewModel.fuzzyLocation {
                PrivacyChoiceRow(
                    isOn: $viewModel.showsLocation,
                    icon: "mappin.and.ellipse",
                    title: NSLocalizedString("record.location.toggle", value: "公开街区位置", comment: ""),
                    detail: viewModel.showsLocation ? loc.label : nil
                )
            }
        }
    }
}

private struct PrivacyChoiceRow: View {
    @Binding var isOn: Bool
    let icon: String
    let title: String
    let detail: String?

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(alignment: .top, spacing: Spacing.s) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(Color.cinnabar)
                    .frame(width: 30, height: 30)
                    .background(Color.cinnabar.opacity(0.10))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(Color.ink700)
                    if let detail {
                        Text(detail)
                            .font(.caption2)
                            .foregroundStyle(Color.ink500)
                    }
                }
            }
        }
        .tint(.cinnabar)
    }
}
