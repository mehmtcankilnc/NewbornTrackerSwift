import Foundation
import SwiftData

/// A milestone as the list shows it. `log` is nil until the milestone is achieved.
struct MilestoneRow: Identifiable, Equatable {
    let source: ChecklistSource
    let name: String
    let ageLabel: String
    let log: MilestoneLog?

    var id: String { source.id }
    var isDone: Bool { log != nil }
}

enum MilestoneChecklist {
    /// The parent's own moments first (oldest first), then the built-in schedule.
    static func rows(
        entries: [MilestoneEntry],
        customMilestones: [CustomMilestone],
        schedule: [ScheduleItem] = MilestoneSchedule.items
    ) -> [MilestoneRow] {
        let logsByScheduleID = Dictionary(
            entries.map { ($0.scheduleID, $0.log) },
            uniquingKeysWith: { _, latest in latest }
        )

        let custom = customMilestones
            .sorted { $0.createdAt < $1.createdAt }
            .map { milestone in
                MilestoneRow(
                    source: .custom(milestone.id),
                    name: milestone.name,
                    ageLabel: milestone.ageLabel ?? "",
                    log: milestone.log
                )
            }

        let scheduled = schedule.map { item in
            MilestoneRow(
                source: .scheduled(item.id),
                name: String(localized: item.name),
                ageLabel: String(localized: item.age),
                log: logsByScheduleID[item.id]
            )
        }

        return custom + scheduled
    }
}

extension ModelContext {
    /// Marks a milestone achieved, or updates its journal entry.
    func saveMilestone(_ log: MilestoneLog, for source: ChecklistSource, baby: Baby) {
        switch source {
        case .scheduled(let scheduleID):
            if let entry = baby.milestoneEntries.first(where: { $0.scheduleID == scheduleID }) {
                entry.log = log
            } else {
                let entry = MilestoneEntry(scheduleID: scheduleID, log: log)
                insert(entry)
                entry.baby = baby
            }
        case .custom(let id):
            baby.customMilestones.first(where: { $0.id == id })?.log = log
        }
    }

    /// Takes the achieved mark away. A custom milestone stays in the list, a built-in one just becomes open again.
    func clearMilestone(_ source: ChecklistSource, baby: Baby) {
        switch source {
        case .scheduled(let scheduleID):
            for entry in baby.milestoneEntries where entry.scheduleID == scheduleID {
                delete(entry)
            }
        case .custom(let id):
            baby.customMilestones.first(where: { $0.id == id })?.log = nil
        }
    }
}
