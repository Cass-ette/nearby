import SwiftUI
import MapKit

struct PhotoAnnotation: View {
    let cluster: AnnotationCluster
    var onTap: (Post) -> Void = { _ in }
    var onClusterTap: (AnnotationCluster) -> Void = { _ in }

    var body: some View {
        switch cluster.displayMode {
        case .cluster:
            pinView(size: pinSize, ringWidth: ringWidth) {
                onClusterTap(cluster)
            }
        case .photo:
            if let post = cluster.posts.first,
               let thumbData = post.displayThumbnailDataList.first,
               let thumb = ImageDecodeCache.image(from: thumbData) {
                Image(uiImage: thumb)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 42, height: 42)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.paper50, lineWidth: 2.5))
                    .overlay(alignment: .bottomTrailing) {
                        Circle()
                            .fill(Color.cinnabar)
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(Color.paper50, lineWidth: 1.5))
                            .offset(x: 1, y: 1)
                    }
                    .shadow(color: Color.ink900.opacity(0.18), radius: 5, y: 2)
                    .onTapGesture {
                        onTap(post)
                    }
            } else {
                pinView(size: 32, ringWidth: 7) {
                    if let post = cluster.posts.first { onTap(post) }
                }
            }
        case .pin:
            pinView(size: 32, ringWidth: 7) {
                if let post = cluster.posts.first { onTap(post) }
            }
        }
    }

    private var pinSize: CGFloat {
        switch cluster.posts.count {
        case 0...1:
            return 30
        case 2...4:
            return 34
        case 5...8:
            return 38
        default:
            return 42
        }
    }

    private var ringWidth: CGFloat {
        cluster.posts.count > 1 ? 8 : 7
    }

    private func pinView(size: CGFloat, ringWidth: CGFloat, action: @escaping () -> Void) -> some View {
        ZStack {
            Circle()
                .fill(Color.paper50.opacity(0.96))
                .frame(width: size, height: size)
            Circle()
                .fill(Color.cinnabar)
                .frame(width: size * 0.42, height: size * 0.42)
            Circle()
                .stroke(Color.cinnabar.opacity(0.22), lineWidth: ringWidth)
                .frame(width: size - 4, height: size - 4)
        }
        .shadow(color: Color.ink900.opacity(0.12), radius: 5, y: 2)
        .onTapGesture(perform: action)
    }
}
