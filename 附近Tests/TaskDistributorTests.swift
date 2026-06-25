import Testing
import Foundation
@testable import 附近

struct TaskDistributorTests {
    private func makeBank(_ n: Int) -> [DailyTask] {
        (0..<n).map { i in
            DailyTask(
                id: "task_\(i)",
                type: .discover,
                title: ["zh": "测试\(i)", "en": "Test \(i)"],
                prompt: ["zh": "提示\(i)", "en": "Prompt \(i)"],
                proposedBy: "@test",
                proposedOn: "2026-01-01",
                voteCount: 100,
                adoptedOn: "2026-01-02",
                referenceImageName: nil,
                cityTags: ["上海"]
            )
        }
    }

    @Test func sameDateReturnsSameTask() {
        let bank = makeBank(30)
        let date = Date(timeIntervalSince1970: 1_750_000_000)
        let task1 = TaskDistributor.task(for: date, bank: bank)
        let task2 = TaskDistributor.task(for: date, bank: bank)
        #expect(task1.id == task2.id)
    }

    @Test func differentDaysInShanghaiTimezoneReturnDifferentTasks() {
        let bank = makeBank(30)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Shanghai")!

        let day1 = cal.date(from: DateComponents(year: 2026, month: 6, day: 25, hour: 12))!
        let day2 = cal.date(from: DateComponents(year: 2026, month: 6, day: 26, hour: 12))!

        let task1 = TaskDistributor.task(for: day1, bank: bank)
        let task2 = TaskDistributor.task(for: day2, bank: bank)
        #expect(task1.id != task2.id)
    }

    @Test func midnightCrossoverUsesShanghaiTimezone() {
        let bank = makeBank(30)
        let utcLate = ISO8601DateFormatter().date(from: "2026-06-25T15:30:00Z")!   // 23:30 SHA
        let utcEarly = ISO8601DateFormatter().date(from: "2026-06-25T16:30:00Z")!  // 00:30 next day SHA

        let task1 = TaskDistributor.task(for: utcLate, bank: bank)
        let task2 = TaskDistributor.task(for: utcEarly, bank: bank)
        #expect(task1.id != task2.id, "23:30 vs 00:30 Shanghai should cross day boundary → different tasks")
    }

    @Test func wrapsAroundCorrectly() {
        let bank = makeBank(3)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Shanghai")!

        let day1 = cal.date(from: DateComponents(year: 2026, month: 6, day: 25))!
        let day2 = cal.date(from: DateComponents(year: 2026, month: 6, day: 26))!
        let day3 = cal.date(from: DateComponents(year: 2026, month: 6, day: 27))!
        let day4 = cal.date(from: DateComponents(year: 2026, month: 6, day: 28))!

        let ids = [day1, day2, day3, day4].map { TaskDistributor.task(for: $0, bank: bank).id }
        #expect(ids[0] == ids[3], "Day 4 should wrap to same task as Day 1 (bank size 3)")
        #expect(ids[0] != ids[1])
        #expect(ids[1] != ids[2])
    }
}
