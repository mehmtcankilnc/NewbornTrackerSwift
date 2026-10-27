import AppIntents
import Foundation
import SwiftData
import UserNotifications
import WidgetKit

/// The "Stop" button of the sleep Live Activity. As a LiveActivityIntent it runs inside the app's process,
/// even when the app was closed, so it can write to the database directly.
struct StopSleepIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Stop sleep"

    @Parameter(title: "Baby")
    var babyID: String

    init() {}

    init(babyID: UUID) {
        self.babyID = babyID.uuidString
    }

    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: babyID) else { return .result() }

        let container = try await MainActor.run { try AppSchema.makeContainer() }
        let notificationID = try await MainActor.run {
            let babies = try container.mainContext.fetch(FetchDescriptor<Baby>(predicate: #Predicate { $0.id == id }))
            return babies.first?.activeSleep?.notificationID
        }

        _ = try await RecordService(modelContainer: container).finishSleep(babyID: id)

        if let notificationID {
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notificationID])
        }
        await SleepLiveActivity.end()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
