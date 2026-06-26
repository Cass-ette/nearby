import Testing
import Foundation
@testable import 附近

struct BadgeTests {
    private func makePost(daysAgo: Int, type: TaskType, isOwn: Bool = true) -> Post {
        let date = Calendar(identifier: .gregorian).date(byAdding: .day, value: -daysAgo, to: Date())!
        return Post(createdAt: date,
                    taskRef: type.rawValue,
                    imageData: Data(), thumbnailData: Data(),
                    text: "x", moodTag: nil,
                    fuzzyLabel: "", fuzzyLat: 0, fuzzyLon: 0,
                    isOwn: isOwn, authorId: CurrentUser.id, authorName: "你")
    }

    @Test func sevenDayStreakUnlocks() {
        let posts = (0..<7).map { makePost(daysAgo: $0, type: .discover) }
        let badges = Badge.evaluate(posts: posts, streak: 7)
        #expect(badges.contains(.sevenDay))
        #expect(!badges.contains(.month))
    }

    @Test func allTaskTypesUnlocksFiveSenses() {
        let bank = TaskBank.loadSync()
        // Use real task IDs from bank, one per type
        var posts: [Post] = []
        for type in TaskType.allCases {
            if let task = bank.first(where: { $0.type == type }) {
                posts.append(makePost(daysAgo: posts.count, type: type).also { $0.taskRef = task.id })
            }
        }
        let badges = Badge.evaluate(posts: posts, streak: 0)
        #expect(badges.contains(.fiveSenses))
    }

    @Test func cityWalkerUnlocksAtTen() {
        let posts = (0..<10).map { makePost(daysAgo: $0, type: .discover) }
        let badges = Badge.evaluate(posts: posts, streak: 0)
        #expect(badges.contains(.cityWalker))
        #expect(!badges.contains(.presence))
    }

    @Test func emptyPostsUnlocksNothing() {
        let badges = Badge.evaluate(posts: [], streak: 0)
        #expect(badges.isEmpty)
    }
}

private extension Post {
    @discardableResult
    func also(_ mutate: (inout Post) -> Void) -> Post {
        var copy = self
        mutate(&copy)
        return copy
    }
}
