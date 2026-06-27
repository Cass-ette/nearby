import Foundation

struct MockSceneCaption: Codable {
    let sceneId: Int
    let title: LocalizedText
    let text: LocalizedText
}

struct MockSceneCaptionFile: Codable {
    let captions: [MockSceneCaption]
}

enum MockSceneCaptions {
    private nonisolated(unsafe) static var cache: [Int: MockSceneCaption]?

    static func load() -> [Int: MockSceneCaption] {
        if let cache { return cache }
        guard let url = Bundle.main.url(forResource: "mock_scene_captions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(MockSceneCaptionFile.self, from: data) else {
            return [:]
        }
        let map = Dictionary(uniqueKeysWithValues: file.captions.map { ($0.sceneId, $0) })
        cache = map
        return map
    }
}
