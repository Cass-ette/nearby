import SwiftUI
import SwiftData

@MainActor
@Observable
final class TodayViewModel {
    var todayTask: DailyTask?
    var hasCompletedToday: Bool = false
    var showRecord: Bool = false

    func load(modelContext: ModelContext, taskBank: [DailyTask]) {
        todayTask = TaskDistributor.task(for: Date(), bank: taskBank)
        if let task = todayTask {
            let taskId = task.id
            let cal = Calendar(identifier: .gregorian)
            let start = cal.startOfDay(for: Date())
            let end = cal.date(byAdding: .day, value: 1, to: start)!
            let predicate = #Predicate<Post> { $0.taskRef == taskId && $0.isOwn == true && $0.createdAt >= start && $0.createdAt < end }
            let descriptor = FetchDescriptor<Post>(predicate: predicate)
            hasCompletedToday = ((try? modelContext.fetchCount(descriptor)) ?? 0) > 0
        }
    }
}
