import SwiftUI

struct MoodSelector: View {
    @Binding var selected: MoodTag?

    var body: some View {
        HStack(spacing: Spacing.m) {
            ForEach(MoodTag.allCases) { mood in
                Button {
                    selected = (selected == mood) ? nil : mood
                } label: {
                    VStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(mood.color)
                            .frame(width: 16, height: 16)
                            .overlay {
                                if selected == mood {
                                    Circle().stroke(Color.ink900, lineWidth: 1.5)
                                        .padding(-3)
                                }
                            }
                        Text(mood.localizedName)
                            .font(.caption)
                            .foregroundStyle(selected == mood ? Color.ink900 : Color.ink500)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
