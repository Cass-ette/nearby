import SwiftUI
import SwiftData
import MapKit

struct MapView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MapViewModel()
    @State private var navigateToDetail = false
    @State private var detailPost: Post?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $viewModel.cameraPosition) {
                    ForEach(viewModel.clusters) { cluster in
                        Annotation("", coordinate: CLLocationCoordinate2D(latitude: cluster.anchorLat, longitude: cluster.anchorLon)) {
                            PhotoAnnotation(cluster: cluster) { post in
                                viewModel.select(post: post)
                            } onClusterTap: { cluster in
                                viewModel.focus(on: cluster)
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .flat))
                .mapControls {
                    MapCompass()
                }
                .onMapCameraChange(frequency: .onEnd) { context in
                    viewModel.updateVisibleRegion(context.region)
                }

                VStack {
                    MapInsightCard(postCount: viewModel.posts.count)
                        .padding(.horizontal, Spacing.l)
                        .padding(.top, Spacing.m)
                    Spacer()
                }

                if viewModel.posts.isEmpty {
                    EmptyMapState()
                        .padding(.horizontal, Spacing.xl)
                        .transition(.opacity)
                }

                if viewModel.showMiniPreview, let post = viewModel.selectedPost {
                    MiniPreviewCard(post: post) {
                        detailPost = post
                        navigateToDetail = true
                        viewModel.showMiniPreview = false
                    }
                    .padding(.horizontal, Spacing.m)
                    .padding(.bottom, Spacing.l)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle(NSLocalizedString("map.nav_title", value: "我的附近", comment: ""))
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
}

private struct MapInsightCard: View {
    let postCount: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "mappin.and.ellipse")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.cinnabar)
            Text(String(format: NSLocalizedString("map.record_count", value: "你已经记录了 %d 个地点", comment: ""), postCount))
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.ink700)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.thinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.paper50.opacity(0.85), lineWidth: 0.8)
        )
        .shadow(color: Color.ink900.opacity(0.08), radius: 10, y: 3)
    }
}

private struct EmptyMapState: View {
    var body: some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: "map")
                .font(.system(size: 34))
                .foregroundStyle(Color.cinnabar.opacity(0.85))
            Text(NSLocalizedString("map.empty_title", value: "还没有点亮任何地方", comment: ""))
                .font(.sectionTitle)
                .foregroundStyle(Color.ink900)
            Text(NSLocalizedString("map.empty_body", value: "留下一条记录，这里就会出现第一个属于你的地点。", comment: ""))
                .font(.bodySerif)
                .foregroundStyle(Color.ink500)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
        .background(.thinMaterial)
        .cornerRadius(Radius.card)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .stroke(Color.ink300.opacity(0.7), lineWidth: 0.5)
        )
    }
}
