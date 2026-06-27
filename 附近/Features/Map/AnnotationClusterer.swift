import Foundation
import MapKit

struct AnnotationCluster: Identifiable {
    let id: String
    let anchorLat: Double
    let anchorLon: Double
    let posts: [Post]
    let displayMode: DisplayMode

    enum DisplayMode {
        case photo
        case pin
        case cluster
    }

    var isMerged: Bool { displayMode == .cluster }
}

enum AnnotationClusterer {
    static func cluster(posts: [Post], gridSize: Double = 0.001) -> [AnnotationCluster] {
        let mode = displayMode(for: gridSize)
        var buckets: [String: [Post]] = [:]
        for post in posts {
            let key = String(format: "%.3f_%.3f",
                             (post.fuzzyLat / gridSize).rounded() * gridSize,
                             (post.fuzzyLon / gridSize).rounded() * gridSize)
            buckets[key, default: []].append(post)
        }
        return buckets.map { key, posts in
            let lat = posts.reduce(0) { $0 + $1.fuzzyLat } / Double(posts.count)
            let lon = posts.reduce(0) { $0 + $1.fuzzyLon } / Double(posts.count)
            let displayMode: AnnotationCluster.DisplayMode = posts.count > 1 ? .cluster : mode
            return AnnotationCluster(id: key, anchorLat: lat, anchorLon: lon, posts: posts, displayMode: displayMode)
        }
        .sorted {
            if $0.posts.count == $1.posts.count {
                return $0.id < $1.id
            }
            return $0.posts.count > $1.posts.count
        }
    }

    static func gridSize(for region: MKCoordinateRegion?) -> Double {
        guard let region else { return 0.001 }
        let latitudinalMeters = region.span.latitudeDelta * 111_000
        switch latitudinalMeters {
        case ..<900:
            return 0.00035
        case ..<1_800:
            return 0.001
        case ..<3_000:
            return 0.0025
        case ..<8_000:
            return 0.006
        case ..<20_000:
            return 0.014
        default:
            return 0.03
        }
    }

    private static func displayMode(for gridSize: Double) -> AnnotationCluster.DisplayMode {
        gridSize <= 0.00035 ? .photo : .pin
    }
}
