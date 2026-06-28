import SwiftUI

struct PostCardView: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(spacing: Spacing.s) {
                Text(post.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(Color.ink500)
                if let label = post.publicFuzzyLabel {
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(Color.ink300)
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(Color.ink500)
                }
                if let mood = post.moodTag {
                    Circle()
                        .fill(mood.color)
                        .frame(width: 8, height: 8)
                }
                Spacer()
            }

            PostPhotoGroup(post: post)

            if let title = post.title {
                Text(title)
                    .font(.taskTitle)
                    .foregroundStyle(Color.ink900)
                    .lineSpacing(3)
            }

            if !post.text.isEmpty {
                Text(post.text)
                    .font(.bodySerif)
                    .foregroundStyle(Color.ink700)
                    .lineSpacing(4)
                    .lineLimit(3)
            }
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .nearbyCard(fill: .surfaceElevated, strokeOpacity: 0.14, shadowOpacity: 0.045)
        .padding(.horizontal, Spacing.m)
        .padding(.bottom, Spacing.s)
    }
}

private struct PostPhotoGroup: View {
    let post: Post

    private var imageDataList: [Data] {
        Array(post.displayImageDataList.prefix(3))
    }

    var body: some View {
        if let firstData = imageDataList.first {
            GeometryReader { proxy in
                if imageDataList.count == 1 {
                    AsyncDecodedImage(data: firstData) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: 320)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.paper100)
                            .frame(width: proxy.size.width, height: 320)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: Radius.image, style: .continuous))
                } else {
                    PhotoDeck(imageDataList: imageDataList, photoCount: post.photoCount, availableWidth: proxy.size.width)
                }
            }
            .frame(height: imageDataList.count == 1 ? 320 : 348)
        }
    }
}

private struct PhotoDeck: View {
    let imageDataList: [Data]
    let photoCount: Int
    let availableWidth: CGFloat

    private let height: CGFloat = 320
    private let revealOffset: CGFloat = 10
    private let visibleDepth: CGFloat = 2

    var body: some View {
        let deckWidth = max(0, availableWidth - revealOffset * visibleDepth)

        ZStack(alignment: .topLeading) {
            ForEach(Array(imageDataList.enumerated().reversed()), id: \.offset) { index, imageData in
                AsyncDecodedImage(data: imageData) { image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: deckWidth, height: height)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.paper100)
                        .frame(width: deckWidth, height: height)
                }
                    .clipShape(RoundedRectangle(cornerRadius: Radius.image, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.image, style: .continuous)
                            .stroke(Color.paper50.opacity(index == 0 ? 0.88 : 0.72), lineWidth: index == 0 ? 1.2 : 1)
                    )
                    .shadow(
                        color: Color.ink900.opacity(index == 0 ? 0.16 : 0.08),
                        radius: index == 0 ? 14 : 8,
                        x: 0,
                        y: index == 0 ? 8 : 4
                    )
                    .rotationEffect(.degrees(rotation(for: index)), anchor: .center)
                    .scaleEffect(1 - CGFloat(index) * 0.025, anchor: .center)
                    .offset(x: CGFloat(index) * revealOffset, y: CGFloat(index) * 11)
                    .zIndex(Double(3 - index))
            }
        }
        .overlay(alignment: .topTrailing) {
            Label("\(photoCount)", systemImage: "rectangle.stack.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.paper50)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.ink900.opacity(0.55))
                .clipShape(Capsule())
                .padding(Spacing.s)
        }
        .overlay(alignment: .bottomTrailing) {
            if photoCount > 3 {
                Text("+\(photoCount - 3)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.ink700)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.paper100.opacity(0.92))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.ink300.opacity(0.20), lineWidth: 0.8))
                    .padding(.trailing, 18)
                    .padding(.bottom, 6)
            }
        }
        .frame(height: height + 28)
    }

    private func rotation(for index: Int) -> Double {
        switch index {
        case 1: 2.4
        case 2: -2.0
        default: 0
        }
    }

}
