import ActivityKit
import Foundation

/// What the sleep Live Activity shows. The timer needs only the start time, so nothing changes while it runs.
nonisolated struct SleepActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {}

    let babyID: UUID
    let babyName: String
    let startedAt: Date
}
