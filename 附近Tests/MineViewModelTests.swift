import Testing
import Foundation
@testable import 附近

struct MineViewModelTests {
    private func makePost(day: Int, hour: Int) -> Post {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: day, hour: hour))!
        return Post(
            createdAt: date,
            taskRef: "x",
            imageData: Data(),
            thumbnailData: Data(),
            text: "test",
            fuzzyLabel: "",
            fuzzyLat: 0,
            fuzzyLon: 0,
            isOwn: true,
            authorId: CurrentUser.id,
            authorName: "你"
        )
    }

    @MainActor
    @Test func recordDayCountCountsUniqueDaysOnly() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let posts = [
            makePost(day: 25, hour: 9),
            makePost(day: 25, hour: 21),
            makePost(day: 26, hour: 12)
        ]

        #expect(MineViewModel.computeRecordDayCount(posts: posts, calendar: calendar) == 2)
    }
}
