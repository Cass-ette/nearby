import Foundation

struct AnnotationCluster: Identifiable {
    let id: String
    let anchorLat: Double
    let anchorLon: Double
    let posts: [Post]

    var isMerged: Bool { posts.count > 3 }
}

enum AnnotationClusterer {
    static func cluster(posts: [Post], gridSize: Double = 0.001) -> [AnnotationCluster] {
        var buckets: [String: [Post]] = [:]
        for post in posts {
            let key = String(format: "%.3f_%.3f",
                             (post.fuzzyLat / gridSize).rounded() * gridSize,
                             (post.fuzzyLon / gridSize).rounded() * gridSize)
            buckets[key, default: []].append(post)
        }
        return buckets.map { key, posts in
            let coords = key.split(separator: "_")
            let lat = Double(coords.first ?? "0") ?? 0
            let lon = Double(coords.last ?? "0") ?? 0
            return AnnotationCluster(id: key, anchorLat: lat, anchorLon: lon, posts: posts)
        }
    }
}
