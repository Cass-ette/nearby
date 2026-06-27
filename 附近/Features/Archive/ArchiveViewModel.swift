import SwiftUI
import SwiftData

@MainActor
@Observable
final class ArchiveViewModel {
    var groupedTasks: [(month: String, tasks: [DailyTask])] = []
    var postCountByTask: [String: Int] = [:]
    var latestPostThumbByTask: [String: Data] = [:]

    func load(modelContext: ModelContext) {
        let bank = TaskBank.loadSync()
        let posts = (try? modelContext.fetch(FetchDescriptor<Post>())) ?? []
        let grouped = Dictionary(grouping: posts, by: { $0.taskRef })
        postCountByTask = grouped.mapValues { $0.count }
        latestPostThumbByTask = grouped.compactMapValues { posts in
            posts.max(by: { $0.createdAt < $1.createdAt })?.thumbnailData
        }

        let calendar = Calendar(identifier: .gregorian)
        var byMonth: [String: [DailyTask]] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        for task in bank {
            guard let date = formatter.date(from: task.adoptedOn) else { continue }
            let components = calendar.dateComponents([.year, .month], from: date)
            let key = String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
            byMonth[key, default: []].append(task)
        }
        groupedTasks = byMonth.keys.sorted(by: >).map { key in
            (month: key, tasks: byMonth[key]!.sorted { $0.adoptedOn > $1.adoptedOn })
        }
    }

    func monthLabel(_ key: String) -> String {
        let parts = key.split(separator: "-")
        guard parts.count == 2, let monthInt = Int(parts[1]) else { return key }
        let lang = Locale.current.language.languageCode?.identifier ?? "zh"
        let enMonths = ["January", "February", "March", "April", "May", "June",
                        "July", "August", "September", "October", "November", "December"]
        return lang == "en"
            ? "\(enMonths[monthInt - 1]) \(parts[0])"
            : "\(parts[0]) 年 \(monthInt) 月"
    }
}
