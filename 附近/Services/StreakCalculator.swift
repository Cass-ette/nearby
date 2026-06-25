import Foundation

enum StreakCalculator {
    private static var shanghaiCalendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return c
    }()

    static func compute(posts: [Post], today: Date = Date()) -> Int {
        let cal = shanghaiCalendar
        let ownStartOfDays = Set(
            posts
                .filter { $0.isOwn }
                .map { cal.startOfDay(for: $0.createdAt) }
        )
        var streak = 0
        var cursor = cal.startOfDay(for: today)
        if !ownStartOfDays.contains(cursor) {
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
        }
        while ownStartOfDays.contains(cursor) {
            streak += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
        }
        return streak
    }
}
