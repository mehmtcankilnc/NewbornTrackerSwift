import Foundation
import SwiftData

/// A built-in schedule vaccine marked as done. Custom vaccines track completion themselves.
@Model
final class VaccineCompletion {
    var scheduleID: String
    var baby: Baby?

    init(scheduleID: String) {
        self.scheduleID = scheduleID
    }
}
