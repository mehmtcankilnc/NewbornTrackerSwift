import ActivityKit
import Foundation

/// Starts and ends the sleep Live Activity. Used by the app and by the "Stop" button of the activity itself.
nonisolated enum SleepLiveActivity {
    static func start(babyID: UUID, babyName: String, startedAt: Date) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        await end()

        let attributes = SleepActivityAttributes(babyID: babyID, babyName: babyName, startedAt: startedAt)
        _ = try? Activity.request(attributes: attributes, content: .init(state: .init(), staleDate: nil))
    }

    static func end() async {
        for activity in Activity<SleepActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
