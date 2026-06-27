import Foundation

enum Badge: String, CaseIterable, Identifiable {
    case sevenDay = "七日同行"
    case month = "月有余温"
    case hundredDay = "百日扎根"
    case fiveSenses = "五感全开"
    case explorer = "探索者"
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
        case .explorer: return "map.fill"
        case .cityWalker: return "figure.walk"
        case .presence: return "mappin"
        case .cityObserver: return "eye"
        }
    }

    var criteriaDescription: String {
        switch self {
        case .sevenDay:
            return NSLocalizedString("badge.criteria.sevenDay", value: "连续 7 天留下记录", comment: "")
        case .month:
            return NSLocalizedString("badge.criteria.month", value: "连续 30 天留下记录", comment: "")
        case .hundredDay:
            return NSLocalizedString("badge.criteria.hundredDay", value: "连续 100 天留下记录", comment: "")
        case .fiveSenses:
            return NSLocalizedString("badge.criteria.fiveSenses", value: "体验过全部 5 种灵感类型：发现、细节、连接、记忆、共同", comment: "")
        case .explorer:
            return NSLocalizedString("badge.criteria.explorer", value: "在 5 个不同的街区留下记录", comment: "")
        case .cityWalker:
            return NSLocalizedString("badge.criteria.cityWalker", value: "累计发布 10 条附近记录", comment: "")
        case .presence:
            return NSLocalizedString("badge.criteria.presence", value: "累计发布 50 条附近记录", comment: "")
        case .cityObserver:
            return NSLocalizedString("badge.criteria.cityObserver", value: "累计发布 100 条附近记录", comment: "")
        }
    }

    static func evaluate(posts: [Post], streak: Int) -> [Badge] {
        let ownPosts = posts.filter { $0.isOwn }
        let ownCount = ownPosts.count
        let taskIds = Set(ownPosts.map { $0.taskRef })
        let taskTypes = Set(taskIds.compactMap { id in
            TaskBank.loadSync().first(where: { $0.id == id })?.type
        })
        let neighborhoodCount = Set(ownPosts.map { $0.fuzzyLabel }).count

        var result: [Badge] = []
        if streak >= 7 { result.append(.sevenDay) }
        if streak >= 30 { result.append(.month) }
        if streak >= 100 { result.append(.hundredDay) }
        if taskTypes.count == 5 { result.append(.fiveSenses) }
        if neighborhoodCount >= 5 { result.append(.explorer) }
        if ownCount >= 10 { result.append(.cityWalker) }
        if ownCount >= 50 { result.append(.presence) }
        if ownCount >= 100 { result.append(.cityObserver) }
        return result
    }
}
