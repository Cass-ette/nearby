import Foundation

enum TaskDistributor {
    private static let shanghai: TimeZone = TimeZone(identifier: "Asia/Shanghai")!

    static func task(for date: Date, bank: [DailyTask]) -> DailyTask {
        precondition(!bank.isEmpty, "Task bank must not be empty")
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = shanghai
        let dayIndex = Int(calendar.startOfDay(for: date).timeIntervalSince1970 / 86400)
        return bank[((dayIndex % bank.count) + bank.count) % bank.count]
    }
}
