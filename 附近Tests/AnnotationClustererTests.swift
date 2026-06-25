import Testing
import Foundation
@testable import 附近

struct AnnotationClustererTests {
    private func makePost(_ lat: Double, _ lon: Double, _ id: String) -> Post {
        Post(id: UUID(uuidString: id.padding(toLength: 36, withPad: "0", startingAt: 0)) ?? UUID(),
             taskRef: "t", imageData: Data(), thumbnailData: Data(),
             text: "x", fuzzyLabel: "x",
             fuzzyLat: lat, fuzzyLon: lon,
             isOwn: false, authorId: UUID(), authorName: "mock")
    }

    @Test func clusterSinglePostReturnsOneCluster() {
        let posts = [makePost(31.226, 121.427, "1")]
        let clusters = AnnotationClusterer.cluster(posts: posts, gridSize: 0.001)
        #expect(clusters.count == 1)
        #expect(clusters.first?.posts.count == 1)
    }

    @Test func clusterMergesPostsInSameGrid() {
        let posts = [
            makePost(31.2261, 121.4271, "1"),
            makePost(31.2262, 121.4272, "2"),
            makePost(31.2263, 121.4273, "3")
        ]
        let clusters = AnnotationClusterer.cluster(posts: posts, gridSize: 0.001)
        #expect(clusters.count == 1, "Expected 1 cluster, got \(clusters.count)")
        #expect(clusters.first?.posts.count == 3)
    }

    @Test func clusterSeparatesPostsInDifferentGrids() {
        let posts = [
            makePost(31.226, 121.427, "1"),
            makePost(31.230, 121.430, "2")
        ]
        let clusters = AnnotationClusterer.cluster(posts: posts, gridSize: 0.001)
        #expect(clusters.count == 2)
    }

    @Test func clusterSizeThresholdAt4() {
        let posts = (0..<5).map { makePost(31.226, 121.427, "\($0)") }
        let clusters = AnnotationClusterer.cluster(posts: posts, gridSize: 0.001)
        #expect(clusters.count == 1)
        #expect(clusters.first?.isMerged == true)
    }
}
