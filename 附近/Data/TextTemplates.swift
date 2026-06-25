import Foundation

struct TextTemplates: Codable {
    let postTitles: [LocalizedText]
    let postTexts: [LocalizedText]
    let responses: [LocalizedText]

    enum CodingKeys: String, CodingKey {
        case postTitles = "post_titles"
        case postTexts = "post_texts"
        case responses
    }
}

struct LocalizedText: Codable {
    let zh: String
    let en: String

    func localized() -> String {
        let lang = Locale.current.language.languageCode?.identifier ?? "zh"
        return lang == "en" ? en : zh
    }
}

enum TextTemplatesLoader {
    static func load() -> TextTemplates? {
        guard let url = Bundle.main.url(forResource: "text_templates", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(TextTemplates.self, from: data)
    }
}
