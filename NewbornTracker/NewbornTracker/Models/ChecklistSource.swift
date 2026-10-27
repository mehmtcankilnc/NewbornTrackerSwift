import Foundation

/// Where a checklist row comes from: the built-in schedule, or something the parent added.
enum ChecklistSource: Hashable {
    case scheduled(String)
    case custom(UUID)

    var id: String {
        switch self {
        case .scheduled(let scheduleID): scheduleID
        case .custom(let uuid): uuid.uuidString
        }
    }
}
