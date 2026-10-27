import SwiftData
import UserNotifications

/// Receives what the user does with a notification, even when the app was closed.
/// It runs on the main actor: UIKit expects the "done" callback of these methods on the main thread.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    private let router: AppRouter
    private let container: ModelContainer

    init(router: AppRouter, container: ModelContainer) {
        self.router = router
        self.container = container
    }

    /// Show the banner even while the app is open.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let identifier = response.notification.request.identifier
        let action = SleepNotification.response(
            actionID: response.actionIdentifier,
            userInfo: response.notification.request.content.userInfo
        )

        switch action {
        case .openStopSleep:
            router.pendingRoute = .stopSleep
        case .stopSleep(let babyID):
            // The write itself happens on RecordService's own actor, off the main thread.
            _ = try? await RecordService(modelContainer: container).finishSleep(babyID: babyID)
            center.removeDeliveredNotifications(withIdentifiers: [identifier])
            await SleepLiveActivity.end()
        case nil:
            break
        }
    }
}
