import SwiftUI
import SwiftData
import CoreLocation

struct MapView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MapViewModel()
    @State private var navigateToDetail = false
    @State private var detailPost: Post?

    private let maxDistanceMeters: Double = 1000
    private let ringDistances: [Double] = [200, 500, 1000]

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let maxRadius = min(geo.size.width, geo.size.height) / 2 - 32
                let userCoord = viewModel.locationManager.currentCoord ?? LocationManager.fallbackCoord

                ZStack {
                    Color.paper50.ignoresSafeArea()

                    fogOverlay(maxRadius: maxRadius, center: center)

                    ForEach(ringDistances, id: \.self) { dist in
                        let r = (dist / maxDistanceMeters) * maxRadius
                        Circle()
                            .stroke(Color.ink300.opacity(0.5), style: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
                            .frame(width: r * 2, height: r * 2)
                            .position(center)
                    }

                    ForEach(ringDistances, id: \.self) { dist in
                        let r = (dist / maxDistanceMeters) * maxRadius
                        Text(distanceLabel(dist))
                            .font(.caption2)
                            .foregroundStyle(Color.ink300)
                            .position(x: center.x + 4, y: center.y - r)
                    }

                    ForEach(viewModel.clusters) { cluster in
                        let clusterCoord = CLLocationCoordinate2D(latitude: cluster.anchorLat, longitude: cluster.anchorLon)
                        let projection = project(clusterCoord, from: userCoord, center: center, maxRadius: maxRadius)
                        let dist = distanceMeters(clusterCoord, from: userCoord)

                        if dist <= maxDistanceMeters * 1.4 {
                            PolarMarker(cluster: cluster, distance: dist, maxDistance: maxDistanceMeters) { post in
                                viewModel.select(post: post)
                            }
                            .position(projection)
                            .accessibilityLabel(Text(cluster.posts.first?.fuzzyLabel ?? "附近"))
                        }
                    }

                    UserPin()
                        .position(center)

                    if viewModel.showMiniPreview, let post = viewModel.selectedPost {
                        VStack {
                            Spacer()
                            MiniPreviewCard(post: post) {
                                detailPost = post
                                navigateToDetail = true
                                viewModel.showMiniPreview = false
                            }
                            .padding(.horizontal, Spacing.m)
                            .padding(.bottom, Spacing.l)
                        }
                        .ignoresSafeArea(edges: .bottom)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.showMiniPreview = false
                }
            }
            .navigationTitle(NSLocalizedString("map.nav_title", value: "附近的人在记录", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.paper50, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .containerBackground(Color.paper50, for: .navigation)
            .navigationDestination(isPresented: $navigateToDetail) {
                if let post = detailPost {
                    PostDetailView(post: post)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.showMiniPreview)
        }
        .paperBackground()
        .task {
            viewModel.load(modelContext: modelContext)
        }
    }

    private func fogOverlay(maxRadius: CGFloat, center: CGPoint) -> some View {
        RadialGradient(
            colors: [
                Color.paper50.opacity(0),
                Color.paper50.opacity(0),
                Color.paper50.opacity(0.9)
            ],
            center: .center,
            startRadius: 0,
            endRadius: maxRadius * 1.15
        )
        .ignoresSafeArea()
    }

    private func project(_ coord: CLLocationCoordinate2D, from user: CLLocationCoordinate2D, center: CGPoint, maxRadius: CGFloat) -> CGPoint {
        let dx = (coord.longitude - user.longitude) * 111_320 * cos(user.latitude * .pi / 180)
        let dy = (coord.latitude - user.latitude) * 110_540
        let scale = Double(maxRadius) / maxDistanceMeters
        let screenDX = CGFloat(dx * scale)
        let screenDY = CGFloat(-dy * scale)
        return CGPoint(x: center.x + screenDX, y: center.y + screenDY)
    }

    private func distanceMeters(_ coord: CLLocationCoordinate2D, from user: CLLocationCoordinate2D) -> Double {
        let dx = (coord.longitude - user.longitude) * 111_320 * cos(user.latitude * .pi / 180)
        let dy = (coord.latitude - user.latitude) * 110_540
        return (dx * dx + dy * dy).squareRoot()
    }

    private func distanceLabel(_ meters: Double) -> String {
        if meters >= 1000 {
            return "\(Int(meters / 1000))km"
        }
        return "\(Int(meters))m"
    }
}

private struct UserPin: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.cinnabar.opacity(0.15))
                .frame(width: 36, height: 36)
            Circle()
                .fill(Color.cinnabar)
                .frame(width: 10, height: 10)
        }
    }
}

private struct PolarMarker: View {
    let cluster: AnnotationCluster
    let distance: Double
    let maxDistance: Double
    let onTap: (Post) -> Void

    var body: some View {
        let fade = max(0.25, 1.0 - (distance / maxDistance) * 0.7)
        let size: CGFloat = cluster.posts.count > 1 ? 50 : 40

        ZStack {
            Circle()
                .fill(Color.paper50)
                .overlay(
                    Circle().stroke(Color.cinnabar.opacity(0.6), lineWidth: 1.5)
                )
                .frame(width: size, height: size)
                .overlay {
                    if let post = cluster.posts.first, let thumb = UIImage(data: post.thumbnailData) {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                            .frame(width: size - 4, height: size - 4)
                            .clipShape(Circle())
                    }
                }

            if cluster.posts.count > 1 {
                Text("\(cluster.posts.count)")
                    .font(.caption2.bold())
                    .foregroundStyle(Color.paper50)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.cinnabar)
                    .clipShape(Capsule())
                    .offset(x: size / 2 - 2, y: -size / 2 + 2)
            }
        }
        .opacity(fade)
        .accessibilityElement(children: .ignore)
        .onTapGesture {
            if let post = cluster.posts.first {
                onTap(post)
            }
        }
    }
}
