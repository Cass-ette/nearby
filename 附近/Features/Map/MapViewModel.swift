import SwiftUI
import SwiftData
import CoreLocation
import MapKit

@MainActor
@Observable
final class MapViewModel {
    var clusters: [AnnotationCluster] = []
    var selectedPost: Post?
    var cameraPosition: MapCameraPosition = .automatic
    var showMiniPreview: Bool = false

    let locationManager = LocationManager()

    func load(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Post>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let posts = try? modelContext.fetch(descriptor) {
            clusters = AnnotationClusterer.cluster(posts: posts)
        }
        updateCamera()
    }

    func updateCamera() {
        let coord = locationManager.currentCoord ?? LocationManager.fallbackCoord
        let region = MKCoordinateRegion(
            center: coord,
            latitudinalMeters: 1500,
            longitudinalMeters: 1500
        )
        cameraPosition = .region(region)
    }

    func select(post: Post) {
        selectedPost = post
        showMiniPreview = true
    }
}
