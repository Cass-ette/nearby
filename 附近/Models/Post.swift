import Foundation
import SwiftData

@Model
final class Post {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var taskRef: String
    var imageData: Data
    var thumbnailData: Data
    var imageDataList: [Data] = []
    var thumbnailDataList: [Data] = []
    var title: String?
    var text: String
    var moodTagRaw: String?
    var filterName: String?
    var fuzzyLabel: String
    var fuzzyLat: Double
    var fuzzyLon: Double
    var isPublic: Bool = true
    var showsLocation: Bool = true
    var isOwn: Bool
    var authorId: UUID
    var authorName: String

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        taskRef: String,
        imageData: Data,
        thumbnailData: Data,
        imageDataList: [Data] = [],
        thumbnailDataList: [Data] = [],
        title: String? = nil,
        text: String,
        moodTag: MoodTag? = nil,
        filterName: String? = nil,
        fuzzyLabel: String,
        fuzzyLat: Double,
        fuzzyLon: Double,
        isPublic: Bool = true,
        showsLocation: Bool = true,
        isOwn: Bool,
        authorId: UUID,
        authorName: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.taskRef = taskRef
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.imageDataList = imageDataList.isEmpty ? [imageData] : imageDataList
        self.thumbnailDataList = thumbnailDataList.isEmpty ? [thumbnailData] : thumbnailDataList
        self.title = title
        self.text = text
        self.moodTagRaw = moodTag?.rawValue
        self.filterName = filterName
        self.fuzzyLabel = fuzzyLabel
        self.fuzzyLat = fuzzyLat
        self.fuzzyLon = fuzzyLon
        self.isPublic = isPublic
        self.showsLocation = showsLocation
        self.isOwn = isOwn
        self.authorId = authorId
        self.authorName = authorName
    }

    var moodTag: MoodTag? {
        guard let raw = moodTagRaw else { return nil }
        return MoodTag(rawValue: raw)
    }

    var publicFuzzyLabel: String? {
        isPublic && showsLocation ? fuzzyLabel : nil
    }

    var displayImageDataList: [Data] {
        imageDataList.isEmpty ? [imageData] : imageDataList
    }

    var displayThumbnailDataList: [Data] {
        thumbnailDataList.isEmpty ? [thumbnailData] : thumbnailDataList
    }

    var photoCount: Int {
        displayImageDataList.count
    }
}
