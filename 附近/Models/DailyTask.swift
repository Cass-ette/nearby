import Foundation

struct DailyTask: Codable, Identifiable, Hashable {
    let id: String
    let type: TaskType
    let title: [String: String]
    let prompt: [String: String]
    let proposedBy: String
    let proposedOn: String
    let voteCount: Int
    let adoptedOn: String
    let referenceImageName: String?
    let cityTags: [String]

    func localizedTitle(for language: String = Locale.current.language.languageCode?.identifier ?? "zh") -> String {
        title[language] ?? title["zh"] ?? title.values.first ?? id
    }

    func localizedPrompt(for language: String = Locale.current.language.languageCode?.identifier ?? "zh") -> String {
        prompt[language] ?? prompt["zh"] ?? prompt.values.first ?? ""
    }
}

struct TaskBankFile: Codable {
    let version: Int
    let tasks: [DailyTask]
}
