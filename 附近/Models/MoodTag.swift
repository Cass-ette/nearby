import SwiftUI

enum MoodTag: String, Codable, CaseIterable, Identifiable {
    case serene = "宁静"
    case curious = "好奇"
    case melancholy = "惆怅"
    case tender = "温柔"
    case surprise = "惊喜"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .serene: return .moodSerene
        case .curious: return .moodCurious
        case .melancholy: return .moodMelancholy
        case .tender: return .moodTender
        case .surprise: return .moodSurprise
        }
    }

    var localizedName: String {
        switch self {
        case .serene: return NSLocalizedString("mood.serene", value: "宁静", comment: "")
        case .curious: return NSLocalizedString("mood.curious", value: "好奇", comment: "")
        case .melancholy: return NSLocalizedString("mood.melancholy", value: "惆怅", comment: "")
        case .tender: return NSLocalizedString("mood.tender", value: "温柔", comment: "")
        case .surprise: return NSLocalizedString("mood.surprise", value: "惊喜", comment: "")
        }
    }
}
