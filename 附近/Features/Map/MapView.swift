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
                    UserAnnotation()
                    ForEach(viewModel.clusters) { cluster in
                        Annotation(cluster.id, coordinate: CLLocationCoordinate2D(latitude: cluster.anchorLat, longitude: cluster.anchorLon)) {
                            PhotoAnnotation(cluster: cluster) { post in
                                viewModel.select(post: post)
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .flat))
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
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
            .navigationTitle(NSLocalizedString("map.nav_title", value: "附近的人在记录", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
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
