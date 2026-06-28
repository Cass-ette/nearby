import SwiftUI
import SwiftData

@MainActor
@Observable
final class FeedViewModel {
    enum Filter: String, CaseIterable, Identifiable {
        case nearby = "nearby"
        case mine = "我的"
        var id: String { rawValue }
        var localizedName: String {
            switch self {
            case .nearby:
                NSLocalizedString("feed.filter.nearby", value: "附近", comment: "")
            case .mine:
                NSLocalizedString("feed.filter.mine", value: "我的", comment: "")
            }
        }
    }

    var filter: Filter = .nearby
    var posts: [Post] = []

    func load(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Post>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        var filteredDescriptor = descriptor
        filteredDescriptor.fetchLimit = 12
        switch filter {
        case .nearby:
            let userId = CurrentUser.id
            filteredDescriptor.predicate = #Predicate<Post> { $0.isPublic == true || $0.authorId == userId }
        case .mine:
            let userId = CurrentUser.id
            filteredDescriptor.predicate = #Predicate<Post> { $0.authorId == userId }
        }
        posts = (try? modelContext.fetch(filteredDescriptor)) ?? []
    }
}
