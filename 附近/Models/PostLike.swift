import Foundation
import SwiftData

@Model
final class PostLike {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var uniqueKey: String
    var createdAt: Date
    var postId: UUID
    var userId: UUID

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        postId: UUID,
        userId: UUID
    ) {
        self.id = id
        self.uniqueKey = PostLike.makeUniqueKey(postId: postId, userId: userId)
        self.createdAt = createdAt
        self.postId = postId
        self.userId = userId
    }

    static func makeUniqueKey(postId: UUID, userId: UUID) -> String {
        "\(userId.uuidString)-\(postId.uuidString)"
    }
}
