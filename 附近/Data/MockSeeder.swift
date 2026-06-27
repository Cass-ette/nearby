import Foundation
import SwiftData
import UIKit
import CoreLocation

enum MockSeeder {
    @MainActor
    static func seedIfNeeded(context: ModelContext, taskBank: [DailyTask]) async {
        let key = "mockSeeder.version3.completed"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        await seed(context: context, taskBank: taskBank)
        UserDefaults.standard.set(true, forKey: key)
    }

    @MainActor
    static func seed(context: ModelContext, taskBank: [DailyTask]) async {
        guard taskBank.count >= 10,
              let users = loadMockUsers(),
              let templates = TextTemplatesLoader.load(),
              let neighborhoods = try? await NeighborhoodTable.load() else {
            return
        }

        let mockImages = (1...20).compactMap { UIImage(named: "mock_scene_\($0)") }
        let placeholderImage = mockImages.first ?? makeFallbackImage()
        let sceneCaptions = MockSceneCaptions.load()

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let now = Date()

        var insertedPosts: [Post] = []
        for i in 0..<40 {
            let task = taskBank[i % taskBank.count]
            let user = users[i % users.count]
            let neighborhood = neighborhoods[i % neighborhoods.count]
            let template = templates.postTexts[i % templates.postTexts.count]
            let mood = MoodTag.allCases[i % MoodTag.allCases.count]
            let filter = ImageFilter.allCases[i % ImageFilter.allCases.count]

            let daysAgo = i / 2
            let hour = 8 + (i % 12)
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
                .addingTimeInterval(TimeInterval((hour - 12) * 3600))

            let jitter = Double(i % 7) * 0.0003
            let coord = CLLocationCoordinate2DMake(
                neighborhood.centerLat + jitter,
                neighborhood.centerLon + jitter
            )
            let labelZh = "\(neighborhood.nameZh) · \(neighborhood.districtZh)"

            let imageIndex = i % max(mockImages.count, 1)
            let sceneId = imageIndex + 1
            let caption = sceneCaptions[sceneId]
            let baseImage = mockImages.isEmpty ? placeholderImage : mockImages[imageIndex]
            let resized = (try? ImageStorage.resize(image: baseImage, maxLongEdge: 2400)) ?? baseImage
            let filtered = (try? ImageFilterEngine.apply(filter: filter, to: resized)) ?? resized
            let fullData = (try? ImageStorage.encodeJPEG(filtered, quality: 0.82)) ?? Data()
            let thumbData = (try? ImageStorage.makeThumbnail(filtered, longEdge: 400, quality: 0.7)) ?? Data()

            let authorId = UUID(uuidString: user.id.replacingOccurrences(of: "mock_", with: "00000000-0000-0000-0000-0000000000").padding(toLength: 36, withPad: "0", startingAt: 0)) ?? UUID()

            let post = Post(
                createdAt: date,
                taskRef: task.id,
                imageData: fullData,
                thumbnailData: thumbData,
                title: caption?.title.localized(),
                text: caption?.text.localized() ?? template.localized(),
                moodTag: mood,
                filterName: filter.rawValue,
                fuzzyLabel: labelZh,
                fuzzyLat: coord.latitude,
                fuzzyLon: coord.longitude,
                isOwn: false,
                authorId: authorId,
                authorName: user.name
            )
            context.insert(post)
            insertedPosts.append(post)
        }

        if let todayTask = taskBank.first {
            let todayCount = 6
            for i in 0..<todayCount {
                let user = users[(i + 3) % users.count]
                let neighborhood = neighborhoods[(i + 2) % neighborhoods.count]
                let template = templates.postTexts[(i + 1) % templates.postTexts.count]
                let mood = MoodTag.allCases[(i + 1) % MoodTag.allCases.count]
                let filter = ImageFilter.allCases[(i + 2) % ImageFilter.allCases.count]

                let coord = CLLocationCoordinate2DMake(neighborhood.centerLat, neighborhood.centerLon)
                let labelZh = "\(neighborhood.nameZh) · \(neighborhood.districtZh)"
                let baseImage = placeholderImage

                let filtered = (try? ImageFilterEngine.apply(filter: filter, to: baseImage)) ?? baseImage
                let fullData = (try? ImageStorage.encodeJPEG(filtered, quality: 0.82)) ?? Data()
                let thumbData = (try? ImageStorage.makeThumbnail(filtered, longEdge: 400, quality: 0.7)) ?? Data()

                let date = calendar.date(byAdding: .hour, value: -(i + 1), to: now)!
                let post = Post(
                    createdAt: date,
                    taskRef: todayTask.id,
                    imageData: fullData,
                    thumbnailData: thumbData,
                    title: nil,
                    text: template.localized(),
                    moodTag: mood,
                    filterName: filter.rawValue,
                    fuzzyLabel: labelZh,
                    fuzzyLat: coord.latitude,
                    fuzzyLon: coord.longitude,
                    isOwn: false,
                    authorId: UUID(),
                    authorName: user.name
                )
                context.insert(post)
                insertedPosts.append(post)
            }
        }

        // Demo user posts: populate Mine tab and unlock badges naturally.
        let ownPostCount = 12
        for i in 0..<ownPostCount {
            let task = taskBank[i % taskBank.count]
            let neighborhood = neighborhoods[i % neighborhoods.count]
            let template = templates.postTexts[i % templates.postTexts.count]
            let mood = MoodTag.allCases[i % MoodTag.allCases.count]
            let filter = ImageFilter.allCases[i % ImageFilter.allCases.count]

            let daysAgo = i % 8
            let hour = 9 + (i % 6)
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
                .addingTimeInterval(TimeInterval((hour - 12) * 3600))

            let jitter = Double(i % 5) * 0.0003
            let coord = CLLocationCoordinate2DMake(
                neighborhood.centerLat + jitter,
                neighborhood.centerLon + jitter
            )
            let labelZh = "\(neighborhood.nameZh) · \(neighborhood.districtZh)"

            let imageIndex = i % max(mockImages.count, 1)
            let sceneId = imageIndex + 1
            let caption = sceneCaptions[sceneId]
            let baseImage = mockImages.isEmpty ? placeholderImage : mockImages[imageIndex]
            let resized = (try? ImageStorage.resize(image: baseImage, maxLongEdge: 2400)) ?? baseImage
            let filtered = (try? ImageFilterEngine.apply(filter: filter, to: resized)) ?? resized
            let fullData = (try? ImageStorage.encodeJPEG(filtered, quality: 0.82)) ?? Data()
            let thumbData = (try? ImageStorage.makeThumbnail(filtered, longEdge: 400, quality: 0.7)) ?? Data()

            let post = Post(
                createdAt: date,
                taskRef: task.id,
                imageData: fullData,
                thumbnailData: thumbData,
                title: caption?.title.localized(),
                text: caption?.text.localized() ?? template.localized(),
                moodTag: mood,
                filterName: filter.rawValue,
                fuzzyLabel: labelZh,
                fuzzyLat: coord.latitude,
                fuzzyLon: coord.longitude,
                isOwn: true,
                authorId: CurrentUser.id,
                authorName: CurrentUser.displayName
            )
            context.insert(post)
            insertedPosts.append(post)
        }

        let responseTemplates = templates.responses
        for post in insertedPosts {
            let responseCount = Int.random(in: 0...3)
            for j in 0..<responseCount {
                let templateIdx = (post.id.hashValue.magnitude + j.magnitude) % responseTemplates.count.magnitude
                let userIdx = (post.id.hashValue.magnitude + j.magnitude) % users.count.magnitude
                let template = responseTemplates[Int(templateIdx)]
                let user = users[Int(userIdx)]
                let response = Response(
                    postId: post.id,
                    text: template.localized(),
                    isOwn: false,
                    authorId: UUID(),
                    authorName: user.name
                )
                context.insert(response)
            }
        }

        // Demo user responses: populate Mine responses tab.
        let ownResponseCount = 5
        let ownResponsePosts = insertedPosts.shuffled().prefix(ownResponseCount)
        for (i, post) in ownResponsePosts.enumerated() {
            let template = responseTemplates[i % responseTemplates.count]
            let response = Response(
                postId: post.id,
                text: template.localized(),
                isOwn: true,
                authorId: CurrentUser.id,
                authorName: CurrentUser.displayName
            )
            context.insert(response)
        }

        try? context.save()
    }

    private static func loadMockUsers() -> [MockUser]? {
        guard let url = Bundle.main.url(forResource: "mock_users", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        struct Wrapper: Codable { let users: [MockUser] }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return (try? decoder.decode(Wrapper.self, from: data))?.users
    }

    private static func makeFallbackImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 750))
        return renderer.image { ctx in
            UIColor(red: 0xE8/255, green: 0xDF/255, blue: 0xC9/255, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: 600, height: 750)))
        }
    }
}

struct MockUser: Codable {
    let id: String
    let name: String
}
