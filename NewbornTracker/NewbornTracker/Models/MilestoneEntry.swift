import Foundation
import SwiftData

/// A built-in schedule milestone that has been achieved. Custom milestones carry their own log.
@Model
final class MilestoneEntry {
    var scheduleID: String
    var log: MilestoneLog
    var baby: Baby?

    init(scheduleID: String, log: MilestoneLog) {
        self.scheduleID = scheduleID
        self.log = log
    }
}
