import SwiftUI
import SwiftData

@MainActor
@Observable
final class TodayViewModel {
    var todayTask: DailyTask?
    var hasCompletedToday: Bool = false
    var todayRecordCount: Int = 0
    var ownRecordCount: Int = 0
    var recentOwnPosts: [Post] = []
    var showRecord: Bool = false

    func load(modelContext: ModelContext, taskBank: [DailyTask]) {
        todayTask = TaskDistributor.task(for: Date(), bank: taskBank)
        let cal = Calendar(identifier: .gregorian)
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start)!

        let todayPredicate = #Predicate<Post> { $0.isOwn == true && $0.createdAt >= start && $0.createdAt < end }
        let todayDescriptor = FetchDescriptor<Post>(predicate: todayPredicate)
        todayRecordCount = (try? modelContext.fetchCount(todayDescriptor)) ?? 0
        hasCompletedToday = todayRecordCount > 0

        let ownPredicate = #Predicate<Post> { $0.isOwn == true }
        let ownDescriptor = FetchDescriptor<Post>(predicate: ownPredicate)
        ownRecordCount = (try? modelContext.fetchCount(ownDescriptor)) ?? 0

        var recentDescriptor = FetchDescriptor<Post>(
            predicate: ownPredicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        recentDescriptor.fetchLimit = 3
        recentOwnPosts = (try? modelContext.fetch(recentDescriptor)) ?? []
    }
}
