import SwiftUI
import SwiftData
import CoreLocation

struct MapView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MapViewModel()
    @State private var navigateToDetail = false
    @State private var detailPost: Post?
    @State private var neighborhoods: [Neighborhood] = []
    @State private var revealRadius: Double = 150
    @State private var tapLits: [CLLocationCoordinate2D] = []

    private let maxDistanceMeters: Double = 1000
    private let ringDistances: [Double] = [200, 500, 1000]
    private let tapLitRadius: Double = 130

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let maxRadius = min(geo.size.width, geo.size.height) / 2 - 32
                let userCoord = viewModel.locationManager.currentCoord ?? LocationManager.fallbackCoord

                ZStack {
                    Color.paper50.ignoresSafeArea()

                    fogOverlay(maxRadius: maxRadius)

                    ForEach(ringDistances, id: \.self) { dist in
                        let r = (dist / maxDistanceMeters) * maxRadius
                        Circle()
                            .stroke(Color.ink300.opacity(0.45), style: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
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

                    ForEach(neighborhoods, id: \.id) { n in
                        let nCoord = CLLocationCoordinate2D(latitude: n.centerLat, longitude: n.centerLon)
                        let dist = distanceMeters(nCoord, from: userCoord)
                        if dist <= maxDistanceMeters * 1.3 {
                            let pos = project(nCoord, from: userCoord, center: center, maxRadius: maxRadius)
                            let lit = litFactor(for: nCoord, userCoord: userCoord)
                            Text(n.nameZh)
                                .font(.caption.weight(.light))
                                .foregroundStyle(Color.ink500.opacity(0.4 + 0.5 * lit))
                                .blur(radius: (1 - lit) * 2.5)
                                .position(pos)
                        }
                    }

                    ForEach(viewModel.clusters) { cluster in
                        let clusterCoord = CLLocationCoordinate2D(latitude: cluster.anchorLat, longitude: cluster.anchorLon)
                        let projection = project(clusterCoord, from: userCoord, center: center, maxRadius: maxRadius)
                        let dist = distanceMeters(clusterCoord, from: userCoord)
                        let lit = litFactor(for: clusterCoord, userCoord: userCoord)

                        if dist <= maxDistanceMeters * 1.4 && lit > 0.05 {
                            PolarMarker(cluster: cluster, lit: lit) { post in
                                viewModel.select(post: post)
                            }
                            .position(projection)
                            .accessibilityLabel(Text(cluster.posts.first?.fuzzyLabel ?? "附近"))
                        }
                    }

                    UserPin(revealRadiusMeters: revealRadius) {
                        revealRadius = min(1000, revealRadius + 200)
                    }
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

                    VStack {
                        HStack {
                            Label("\(viewModel.clusters.count) 位邻居", systemImage: "circle.grid.2x1.fill")
                                .font(.caption)
                                .foregroundStyle(Color.ink700)
                                .padding(.horizontal, Spacing.m)
                                .padding(.vertical, Spacing.s)
                                .background(Color.paper100)
                                .cornerRadius(Radius.button)
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.m)
                    .padding(.top, Spacing.s)
                    .allowsHitTesting(false)
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    let proj = projectPointBack(location, center: center, userCoord: userCoord, maxRadius: maxRadius)
                    tapLits.append(proj)
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
            .animation(.easeInOut(duration: 0.25), value: viewModel.showMiniPreview)
            .animation(.easeInOut(duration: 0.4), value: revealRadius)
            .animation(.easeInOut(duration: 0.4), value: tapLits.count)
        }
        .paperBackground()
        .task {
            viewModel.load(modelContext: modelContext)
            neighborhoods = (try? await NeighborhoodTable.load()) ?? []
        }
    }

    private func fogOverlay(maxRadius: CGFloat) -> some View {
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

    private func litFactor(for coord: CLLocationCoordinate2D, userCoord: CLLocationCoordinate2D) -> Double {
        let userDist = distanceMeters(coord, from: userCoord)
        let userFactor = gaussian(userDist, mu: revealRadius, sigma: 250)
        var bestTap = 0.0
        for tap in tapLits {
            let d = distanceMeters(coord, from: tap)
            bestTap = max(bestTap, gaussian(d, mu: tapLitRadius, sigma: 200))
        }
        return max(0, min(1, max(userFactor, bestTap)))
    }

    private func gaussian(_ x: Double, mu: Double, sigma: Double) -> Double {
        let z = (x - mu) / sigma
        return exp(-0.5 * z * z)
    }

    private func project(_ coord: CLLocationCoordinate2D, from user: CLLocationCoordinate2D, center: CGPoint, maxRadius: CGFloat) -> CGPoint {
        let dx = (coord.longitude - user.longitude) * 111_320 * cos(user.latitude * .pi / 180)
        let dy = (coord.latitude - user.latitude) * 110_540
        let scale = Double(maxRadius) / maxDistanceMeters
        let screenDX = CGFloat(dx * scale)
        let screenDY = CGFloat(-dy * scale)
        return CGPoint(x: center.x + screenDX, y: center.y + screenDY)
    }

    private func projectPointBack(_ point: CGPoint, center: CGPoint, userCoord: CLLocationCoordinate2D, maxRadius: CGFloat) -> CLLocationCoordinate2D {
        let scale = maxDistanceMeters / Double(maxRadius)
        let dx = Double(point.x - center.x) * scale
        let dy = Double(-(point.y - center.y)) * scale
        let dLon = dx / (111_320 * cos(userCoord.latitude * .pi / 180))
        let dLat = dy / 110_540
        return CLLocationCoordinate2D(latitude: userCoord.latitude + dLat, longitude: userCoord.longitude + dLon)
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
    let revealRadiusMeters: Double
    let onTap: () -> Void

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.cinnabar.opacity(0.08))
                .frame(width: 56, height: 56)
            Circle()
                .fill(Color.cinnabar.opacity(0.15))
                .frame(width: 36, height: 36)
            Circle()
                .fill(Color.cinnabar)
                .frame(width: 10, height: 10)
        }
        .contentShape(Circle().inset(by: -16))
        .onTapGesture(perform: onTap)
        .accessibilityLabel(Text("你 · 点亮周围 \(Int(revealRadiusMeters))m"))
    }
}

private struct PolarMarker: View {
    let cluster: AnnotationCluster
    let lit: Double
    let onTap: (Post) -> Void

    var body: some View {
        let size: CGFloat = cluster.posts.count > 1 ? 50 : 40
        let blurRadius: CGFloat = (1 - lit) * 6
        let opacity: Double = max(0.2, lit)

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
        .opacity(opacity)
        .blur(radius: blurRadius)
        .accessibilityElement(children: .ignore)
        .onTapGesture {
            if lit > 0.4, let post = cluster.posts.first {
                onTap(post)
            }
        }
    }
}

