import Foundation
import UserNotifications

/// Everything about the sleep notification that needs no UI: what it says, what data it carries,
/// and how a tap on it is interpreted.
nonisolated enum SleepNotification {
    static let categoryID = "sleep"
    static let stopActionID = "stop-sleep"

    struct Content: Equatable {
        let title: String
        let body: String
        let userInfo: [String: String]
    }

    /// What the app should do after the user interacted with the notification.
    enum Response: Equatable {
        case openStopSleep
        case stopSleep(babyID: UUID)
    }

    static func content(babyID: UUID, startedAt: Date) -> Content {
        let time = startedAt.formatted(date: .omitted, time: .shortened)
        return Content(
            title: String(localized: "Sleep in progress"),
            body: String(localized: "Sleeping since \(time) · Tap to stop"),
            userInfo: ["type": "sleep", "babyID": babyID.uuidString]
        )
    }

    static func response(actionID: String, userInfo: [AnyHashable: Any]) -> Response? {
        guard userInfo["type"] as? String == "sleep" else { return nil }

        switch actionID {
        case UNNotificationDefaultActionIdentifier:
            return .openStopSleep
        case stopActionID:
            guard let id = (userInfo["babyID"] as? String).flatMap(UUID.init(uuidString:)) else { return nil }
            return .stopSleep(babyID: id)
        default:
            return nil
        }
    }
}
