import SwiftUI
import SwiftData
import CoreLocation
import MapKit

@MainActor
@Observable
final class MapViewModel {
    var posts: [Post] = []
    var clusters: [AnnotationCluster] = []
    var selectedPost: Post?
    var cameraPosition: MapCameraPosition = .automatic
    var showMiniPreview: Bool = false
    var visibleRegion: MKCoordinateRegion?

    let locationManager = LocationManager()

    func load(modelContext: ModelContext) {
        let userId = CurrentUser.id
        var descriptor = FetchDescriptor<Post>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.predicate = #Predicate<Post> { $0.authorId == userId }
        posts = (try? modelContext.fetch(descriptor)) ?? []
        recluster()
        updateCamera()
    }

    func updateCamera() {
        let coord = centerOfPosts() ?? locationManager.currentCoord ?? LocationManager.fallbackCoord
        let region = MKCoordinateRegion(
            center: coord,
            latitudinalMeters: posts.isEmpty ? 1500 : 1400,
            longitudinalMeters: posts.isEmpty ? 1500 : 1400
        )
        cameraPosition = .region(region)
        visibleRegion = region
        recluster()
    }

    func select(post: Post) {
        selectedPost = post
        showMiniPreview = true
    }

    func focus(on cluster: AnnotationCluster) {
        let meters = zoomMeters(for: cluster)
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: cluster.anchorLat, longitude: cluster.anchorLon),
            latitudinalMeters: meters,
            longitudinalMeters: meters
        )
        cameraPosition = .region(region)
        visibleRegion = region
        recluster()
    }

    func updateVisibleRegion(_ region: MKCoordinateRegion) {
        visibleRegion = region
        recluster()
    }

    private func recluster() {
        clusters = AnnotationClusterer.cluster(
            posts: posts,
            gridSize: AnnotationClusterer.gridSize(for: visibleRegion)
        )
    }

    private func zoomMeters(for cluster: AnnotationCluster) -> CLLocationDistance {
        guard cluster.posts.count > 1 else { return 500 }
        let lats = cluster.posts.map(\.fuzzyLat)
        let lons = cluster.posts.map(\.fuzzyLon)
        let latSpanMeters = ((lats.max() ?? cluster.anchorLat) - (lats.min() ?? cluster.anchorLat)) * 111_000
        let lonSpanMeters = ((lons.max() ?? cluster.anchorLon) - (lons.min() ?? cluster.anchorLon)) * 96_000
        return max(450, max(latSpanMeters, lonSpanMeters) * 2.5)
    }

    private func centerOfPosts() -> CLLocationCoordinate2D? {
        guard !posts.isEmpty else { return nil }
        let lat = posts.reduce(0) { $0 + $1.fuzzyLat } / Double(posts.count)
        let lon = posts.reduce(0) { $0 + $1.fuzzyLon } / Double(posts.count)
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
