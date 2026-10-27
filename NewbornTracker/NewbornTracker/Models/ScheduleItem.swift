import Foundation

/// One row of a built-in checklist: a vaccine or a milestone.
struct ScheduleItem: Identifiable {
    let id: String
    let age: LocalizedStringResource
    let name: LocalizedStringResource
}
