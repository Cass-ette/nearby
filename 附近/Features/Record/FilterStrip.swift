import SwiftUI

struct FilterStrip: View {
    let originalImage: UIImage
    @Binding var selected: ImageFilter

    @State private var previews: [ImageFilter: UIImage] = [:]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.m) {
                ForEach(ImageFilter.allCases) { filter in
                    Button {
                        selected = filter
                    } label: {
                        VStack(spacing: Spacing.xs) {
                            ZStack {
                                if let preview = previews[filter] {
                                    Image(uiImage: preview)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 56, height: 56)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.paper200)
                                        .frame(width: 56, height: 56)
                                }
                                if selected == filter {
                                    Circle()
                                        .stroke(Color.cinnabar, lineWidth: 2)
                                        .frame(width: 60, height: 60)
                                }
                            }
                            Text(filter.localizedName)
                                .font(.caption)
                                .foregroundStyle(selected == filter ? Color.ink900 : Color.ink500)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.m)
        }
        .task {
            await generatePreviews()
        }
    }

    private func generatePreviews() async {
        let resized = (try? ImageStorage.resize(image: originalImage, maxLongEdge: 120)) ?? originalImage
        for filter in ImageFilter.allCases {
            if let result = try? ImageFilterEngine.apply(filter: filter, to: resized) {
                await MainActor.run {
                    previews[filter] = result
                }
            }
        }
    }
}
