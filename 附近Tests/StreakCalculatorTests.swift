import Testing
import Foundation
@testable import 附近

struct StreakCalculatorTests {
    private func makePost(daysAgo: Int, hour: Int = 12, isOwn: Bool = true) -> Post {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let ref = cal.date(from: DateComponents(year: 2026, month: 6, day: 25, hour: hour))!
        let date = cal.date(byAdding: .day, value: -daysAgo, to: ref)!
        return Post(
            createdAt: date,
            taskRef: "x",
            imageData: Data(),
            thumbnailData: Data(),
            text: "test",
            fuzzyLabel: "",
            fuzzyLat: 0,
            fuzzyLon: 0,
            isOwn: isOwn,
            authorId: CurrentUser.id,
            authorName: "你"
        )
    }

    @Test func returnsZeroWithNoPosts() {
        let today = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 6, day: 25))!
        #expect(StreakCalculator.compute(posts: [], today: today) == 0)
    }

    @Test func returnsZeroWithOnlyOtherUserPosts() {
        let today = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 6, day: 25))!
        let other = makePost(daysAgo: 0, isOwn: false)
        #expect(StreakCalculator.compute(posts: [other], today: today) == 0)
    }

    @Test func countsConsecutiveDays() {
        let today = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 6, day: 25))!
        let posts = [
            makePost(daysAgo: 0),
            makePost(daysAgo: 1),
            makePost(daysAgo: 2)
        ]
        #expect(StreakCalculator.compute(posts: posts, today: today) == 3)
    }

    @Test func breaksOnGap() {
        let today = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 6, day: 25))!
        let posts = [
            makePost(daysAgo: 0),
            makePost(daysAgo: 1),
            makePost(daysAgo: 3)
        ]
        #expect(StreakCalculator.compute(posts: posts, today: today) == 2)
    }

    @Test func todayNotPostedYetCountsFromYesterday() {
        let today = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 6, day: 25))!
        let posts = [
            makePost(daysAgo: 1),
            makePost(daysAgo: 2)
        ]
        #expect(StreakCalculator.compute(posts: posts, today: today) == 2)
    }
}
