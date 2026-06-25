import SwiftUI
import MapKit

struct PhotoAnnotation: View {
    let cluster: AnnotationCluster
    var onTap: (Post) -> Void = { _ in }

    var body: some View {
        if cluster.isMerged {
            ZStack {
                Circle()
                    .fill(Color.cinnabar.opacity(0.85))
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(Color.paper50, lineWidth: 2))
                Text("\(cluster.posts.count)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.paper50)
            }
            .onTapGesture {
                if let first = cluster.posts.first { onTap(first) }
            }
        } else {
            HStack(spacing: 2) {
                ForEach(Array(cluster.posts.prefix(3).enumerated()), id: \.offset) { idx, post in
                    if let thumb = UIImage(data: post.thumbnailData) {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 38, height: 38)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.paper50, lineWidth: 2))
                            .shadow(color: Color.ink900.opacity(0.15), radius: 2, y: 1)
                            .offset(x: CGFloat(idx * 6), y: CGFloat(idx % 2 == 0 ? -2 : 2))
                            .onTapGesture { onTap(post) }
                    }
                }
            }
        }
    }
}
