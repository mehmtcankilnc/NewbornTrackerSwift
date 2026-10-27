import Foundation
import UserNotifications

/// The slice of UNUserNotificationCenter this app uses, so tests can swap in a fake.
nonisolated protocol NotificationCentering {
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization() async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
}

extension UNUserNotificationCenter: NotificationCentering {
    func authorizationStatus() async -> UNAuthorizationStatus {
        await notificationSettings().authorizationStatus
    }

    func requestAuthorization() async throws -> Bool {
        try await requestAuthorization(options: [.alert, .sound])
    }
}

enum NotificationPermission: Equatable {
    case notDetermined
    case allowed
    case denied
}

struct SleepNotificationService {
    let center: NotificationCentering

    func permission() async -> NotificationPermission {
        switch await center.authorizationStatus() {
        case .notDetermined: .notDetermined
        case .authorized, .provisional, .ephemeral: .allowed
        default: .denied
        }
    }

    func requestPermission() async -> Bool {
        (try? await center.requestAuthorization()) ?? false
    }

    /// Shows the "sleep in progress" notification. Returns its id, or nil when notifications are not allowed.
    func notifySleepStarted(babyID: UUID, startedAt: Date) async -> String? {
        guard await permission() == .allowed else { return nil }

        let content = SleepNotification.content(babyID: babyID, startedAt: startedAt)
        let notification = UNMutableNotificationContent()
        notification.title = content.title
        notification.body = content.body
        notification.userInfo = content.userInfo
        notification.categoryIdentifier = SleepNotification.categoryID

        let id = UUID().uuidString
        let request = UNNotificationRequest(identifier: id, content: notification, trigger: nil)

        do {
            try await center.add(request)
            return id
        } catch {
            return nil
        }
    }

    func dismiss(_ id: String?) {
        guard let id else { return }
        center.removeDeliveredNotifications(withIdentifiers: [id])
    }
}

extension SleepNotification {
    /// The category that gives the sleep notification its "Stop sleep" button.
    static func makeCategory() -> UNNotificationCategory {
        let stop = UNNotificationAction(
            identifier: stopActionID,
            title: String(localized: "Stop sleep"),
            options: []
        )
        return UNNotificationCategory(identifier: categoryID, actions: [stop], intentIdentifiers: [])
    }
}
