import Foundation
import SwiftData

@Model
final class Post {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var taskRef: String
    var imageData: Data
    var thumbnailData: Data
    var title: String?
    var text: String
    var moodTagRaw: String?
    var filterName: String?
    var fuzzyLabel: String
    var fuzzyLat: Double
    var fuzzyLon: Double
    var isOwn: Bool
    var authorId: UUID
    var authorName: String

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        taskRef: String,
        imageData: Data,
        thumbnailData: Data,
        title: String? = nil,
        text: String,
        moodTag: MoodTag? = nil,
        filterName: String? = nil,
        fuzzyLabel: String,
        fuzzyLat: Double,
        fuzzyLon: Double,
        isOwn: Bool,
        authorId: UUID,
        authorName: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.taskRef = taskRef
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.title = title
        self.text = text
        self.moodTagRaw = moodTag?.rawValue
        self.filterName = filterName
        self.fuzzyLabel = fuzzyLabel
        self.fuzzyLat = fuzzyLat
        self.fuzzyLon = fuzzyLon
        self.isOwn = isOwn
        self.authorId = authorId
        self.authorName = authorName
    }

    var moodTag: MoodTag? {
        guard let raw = moodTagRaw else { return nil }
        return MoodTag(rawValue: raw)
    }
}
