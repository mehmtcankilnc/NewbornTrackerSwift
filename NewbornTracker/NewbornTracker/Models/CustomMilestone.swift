import Foundation
import SwiftData

@Model
final class CustomMilestone {
    var id: UUID
    var name: String
    var ageLabel: String?
    /// nil until the milestone is achieved.
    var log: MilestoneLog?
    var createdAt: Date = Date.now
    var baby: Baby?

    init(name: String, ageLabel: String? = nil, log: MilestoneLog? = nil) {
        self.id = UUID()
        self.name = name
        self.ageLabel = ageLabel
        self.log = log
    }
}
