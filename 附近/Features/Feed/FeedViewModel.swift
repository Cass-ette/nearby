import SwiftUI
import SwiftData

@MainActor
@Observable
final class FeedViewModel {
    enum Filter: String, CaseIterable, Identifiable {
        case all = "全部"
        case mine = "我的"
        var id: String { rawValue }
        var localizedName: String {
            NSLocalizedString("feed.filter.\(rawValue)", value: rawValue, comment: "")
        }
    }

    var filter: Filter = .all
    var posts: [Post] = []

    func load(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Post>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        var filteredDescriptor = descriptor
        switch filter {
        case .all:
            filteredDescriptor.predicate = #Predicate<Post> { $0.isPublic == true }
        case .mine:
            let userId = CurrentUser.id
            filteredDescriptor.predicate = #Predicate<Post> { $0.authorId == userId }
        }
        posts = (try? modelContext.fetch(filteredDescriptor)) ?? []
    }
}
