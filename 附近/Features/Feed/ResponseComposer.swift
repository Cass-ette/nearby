import SwiftUI
import SwiftData

struct ResponseComposer: View {
    let postId: UUID
    var onSubmitted: (String) -> Void

    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: Spacing.s) {
            TextField(NSLocalizedString("response.placeholder", value: "留下一句回应…", comment: ""), text: $text, axis: .vertical)
                .font(.bodySerif)
                .focused($isFocused)
                .lineLimit(1...3)
                .padding(Spacing.s)
                .background(Color.paper100)
                .cornerRadius(Radius.button)

            Button {
                submit()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.paper50)
                    .frame(width: 32, height: 32)
                    .background(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.ink300 : Color.cinnabar)
                    .clipShape(Circle())
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func submit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let response = Response(
            postId: postId,
            text: trimmed,
            isOwn: true,
            authorId: CurrentUser.id,
            authorName: CurrentUser.displayName
        )
        modelContext.insert(response)
        try? modelContext.save()
        text = ""
        onSubmitted(trimmed)
    }
}
