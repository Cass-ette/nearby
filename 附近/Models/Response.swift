import Foundation
import SwiftData

@Model
final class Response {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var postId: UUID
    var text: String
    var isOwn: Bool
    var authorId: UUID
    var authorName: String

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        postId: UUID,
        text: String,
        isOwn: Bool,
        authorId: UUID,
        authorName: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.postId = postId
        self.text = text
        self.isOwn = isOwn
        self.authorId = authorId
        self.authorName = authorName
    }
}
