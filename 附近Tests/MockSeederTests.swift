import Testing
import Foundation
import SwiftData
@testable import 附近

struct MockSeederTests {
    @MainActor
    @Test func seeds30to50PostsAcrossTenNeighborhoods() async throws {
        let container = try ModelContainer(
            for: Post.self, Response.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let bank = TaskBank.loadSync()
        await MockSeeder.seed(context: context, taskBank: bank)

        let posts = try context.fetch(FetchDescriptor<Post>())
        #expect(posts.count >= 30 && posts.count <= 50, "Expected 30-50 posts, got \(posts.count)")

        let neighborhoods = Set(posts.map { $0.fuzzyLabel })
        #expect(neighborhoods.count >= 5, "Expected ≥5 distinct labels, got \(neighborhoods.count)")
    }

    @MainActor
    @Test func seedsIdempotent() async throws {
        let container = try ModelContainer(
            for: Post.self, Response.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let bank = TaskBank.loadSync()

        await MockSeeder.seedIfNeeded(context: context, taskBank: bank)
        let countAfterFirst = try context.fetchCount(FetchDescriptor<Post>())

        await MockSeeder.seedIfNeeded(context: context, taskBank: bank)
        let countAfterSecond = try context.fetchCount(FetchDescriptor<Post>())

        #expect(countAfterFirst == countAfterSecond, "Seeder should be idempotent")
    }

    @MainActor
    @Test func seedsSomeResponses() async throws {
        let container = try ModelContainer(
            for: Post.self, Response.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let bank = TaskBank.loadSync()

        await MockSeeder.seed(context: context, taskBank: bank)
        let responseCount = try context.fetchCount(FetchDescriptor<Response>())
        #expect(responseCount > 0, "Expected some seeded responses")
    }
}
