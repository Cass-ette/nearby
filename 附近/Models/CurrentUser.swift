import Foundation

enum CurrentUser {
    static let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    private static let nameKey = "currentUser.displayName"

    static var displayName: String {
        get {
            UserDefaults.standard.string(forKey: nameKey) ?? NSLocalizedString("user.default_name", value: "你", comment: "")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: nameKey)
            NotificationCenter.default.post(name: .currentUserDidChange, object: nil)
        }
    }
}

extension Notification.Name {
    static let currentUserDidChange = Notification.Name("currentUserDidChange")
}
