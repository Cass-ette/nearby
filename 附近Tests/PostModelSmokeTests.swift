import Testing
import Foundation
import SwiftData
@testable import 附近

struct PostModelSmokeTests {
    @MainActor
    @Test func canInsertAndFetchPost() throws {
        let container = try ModelContainer(
            for: Post.self, Response.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let post = Post(
            taskRef: "test_task",
            imageData: Data([0xFF]),
            thumbnailData: Data([0xFF]),
            title: "Smoke",
            text: "Hello nearby world",
            moodTag: .serene,
            fuzzyLabel: "愚园路 · 静安",
            fuzzyLat: 31.226,
            fuzzyLon: 121.427,
            isOwn: true,
            authorId: CurrentUser.id,
            authorName: "你"
        )
        context.insert(post)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Post>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.title == "Smoke")
        #expect(fetched.first?.moodTag == .serene)
    }

    @MainActor
    @Test func canInsertResponseLinkedToPost() throws {
        let container = try ModelContainer(
            for: Post.self, Response.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let postId = UUID()
        let post = Post(
            id: postId,
            taskRef: "test",
            imageData: Data(),
            thumbnailData: Data(),
            text: "Post",
            fuzzyLabel: "x",
            fuzzyLat: 0,
            fuzzyLon: 0,
            isOwn: false,
            authorId: UUID(),
            authorName: "Mock"
        )
        context.insert(post)

        let response = Response(
            postId: postId,
            text: "Me too",
            isOwn: true,
            authorId: CurrentUser.id,
            authorName: "你"
        )
        context.insert(response)
        try context.save()

        let responses = try context.fetch(FetchDescriptor<Response>())
        #expect(responses.count == 1)
        #expect(responses.first?.postId == postId)
    }
}
