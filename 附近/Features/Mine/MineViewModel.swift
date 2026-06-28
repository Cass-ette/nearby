import SwiftUI
import SwiftData

@MainActor
@Observable
final class MineViewModel {
    enum Tab: String, CaseIterable, Identifiable {
        case posts = "记录"
        case likes = "喜欢"
        case badges = "徽章"
        var id: String { rawValue }
        var localizedName: String {
            NSLocalizedString("mine.tab.\(rawValue)", value: rawValue, comment: "")
        }
    }

    var selectedTab: Tab = .posts
    var myPosts: [Post] = []
    var likedPosts: [Post] = []
    var streak: Int = 0
    var recordDayCount: Int = 0
    var badges: [Badge] = []

    func load(modelContext: ModelContext) {
        let userId = CurrentUser.id

        var postsDescriptor = FetchDescriptor<Post>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        postsDescriptor.predicate = #Predicate<Post> { $0.authorId == userId }
        myPosts = (try? modelContext.fetch(postsDescriptor)) ?? []

        var likesDescriptor = FetchDescriptor<PostLike>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        likesDescriptor.predicate = #Predicate<PostLike> { $0.userId == userId }
        let likes = (try? modelContext.fetch(likesDescriptor)) ?? []
        let likedIds = Set(likes.map(\.postId))
        let likedAtByPostId = Dictionary(uniqueKeysWithValues: likes.map { ($0.postId, $0.createdAt) })
        let allPosts = (try? modelContext.fetch(FetchDescriptor<Post>())) ?? []
        likedPosts = allPosts
            .filter { likedIds.contains($0.id) }
            .sorted {
                (likedAtByPostId[$0.id] ?? .distantPast) > (likedAtByPostId[$1.id] ?? .distantPast)
            }

        streak = StreakCalculator.compute(posts: myPosts)
        recordDayCount = Self.computeRecordDayCount(posts: myPosts)
        badges = Badge.evaluate(posts: myPosts, streak: streak)
    }

    func delete(post: Post, modelContext: ModelContext) {
        let postId = post.id
        let likeDescriptor = FetchDescriptor<PostLike>(
            predicate: #Predicate<PostLike> { $0.postId == postId }
        )
        let likes = (try? modelContext.fetch(likeDescriptor)) ?? []
        for like in likes {
            modelContext.delete(like)
        }

        modelContext.delete(post)
        try? modelContext.save()
        load(modelContext: modelContext)
    }

    static func computeRecordDayCount(posts: [Post], calendar: Calendar = .current) -> Int {
        Set(posts.map { calendar.startOfDay(for: $0.createdAt) }).count
    }
}
