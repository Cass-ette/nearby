import SwiftUI
import SwiftData

@MainActor
@Observable
final class MineViewModel {
    enum Tab: String, CaseIterable, Identifiable {
        case posts = "记录"
        case responses = "回应"
        case badges = "徽章"
        var id: String { rawValue }
        var localizedName: String {
            NSLocalizedString("mine.tab.\(rawValue)", value: rawValue, comment: "")
        }
    }

    var selectedTab: Tab = .posts
    var myPosts: [Post] = []
    var myResponses: [Response] = []
    var streak: Int = 0
    var badges: [Badge] = []

    func load(modelContext: ModelContext) {
        let userId = CurrentUser.id

        var postsDescriptor = FetchDescriptor<Post>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        postsDescriptor.predicate = #Predicate<Post> { $0.authorId == userId }
        myPosts = (try? modelContext.fetch(postsDescriptor)) ?? []

        var responsesDescriptor = FetchDescriptor<Response>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        responsesDescriptor.predicate = #Predicate<Response> { $0.authorId == userId }
        myResponses = (try? modelContext.fetch(responsesDescriptor)) ?? []

        streak = StreakCalculator.compute(posts: myPosts)
        badges = Badge.evaluate(posts: myPosts, streak: streak, responses: myResponses)
    }
}
