import SwiftUI

enum TaskType: String, Codable, CaseIterable, Identifiable {
    case discover
    case detail
    case connect
    case memory
    case together

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .discover: return NSLocalizedString("task.type.discover", value: "发现", comment: "")
        case .detail: return NSLocalizedString("task.type.detail", value: "细节", comment: "")
        case .connect: return NSLocalizedString("task.type.connect", value: "连接", comment: "")
        case .memory: return NSLocalizedString("task.type.memory", value: "记忆", comment: "")
        case .together: return NSLocalizedString("task.type.together", value: "共同", comment: "")
        }
    }

    var iconName: String {
        switch self {
        case .discover: return "safari"
        case .detail: return "eye"
        case .connect: return "person.wave.2"
        case .memory: return "book"
        case .together: return "globe.asia.australia"
        }
    }
}
