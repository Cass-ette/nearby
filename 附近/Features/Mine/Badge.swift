import Foundation

enum Badge: String, CaseIterable, Identifiable {
    case sevenDay = "七日同行"
    case month = "月有余温"
    case hundredDay = "百日扎根"
    case fiveSenses = "五感全开"
    case cityWalker = "城市行人"
    case presence = "在场"
    case cityObserver = "城市观"

    var id: String { rawValue }

    var localizedName: String {
        NSLocalizedString("badge.\(rawValue)", value: rawValue, comment: "")
    }

    var iconName: String {
        switch self {
        case .sevenDay: return "calendar"
        case .month: return "moon.stars"
        case .hundredDay: return "tree"
        case .fiveSenses: return "hand.point.up.left"
        case .cityWalker: return "figure.walk"
        case .presence: return "mappin"
        case .cityObserver: return "eye"
        }
    }

    static func evaluate(posts: [Post], streak: Int) -> [Badge] {
        let ownPosts = posts.filter { $0.isOwn }
        let ownCount = ownPosts.count
        let taskIds = Set(ownPosts.map { $0.taskRef })
        let taskTypes = Set(taskIds.compactMap { id in
            TaskBank.loadSync().first(where: { $0.id == id })?.type
        })

        var result: [Badge] = []
        if streak >= 7 { result.append(.sevenDay) }
        if streak >= 30 { result.append(.month) }
        if streak >= 100 { result.append(.hundredDay) }
        if taskTypes.count == 5 { result.append(.fiveSenses) }
        if ownCount >= 10 { result.append(.cityWalker) }
        if ownCount >= 50 { result.append(.presence) }
        if ownCount >= 100 { result.append(.cityObserver) }
        return result
    }
}
