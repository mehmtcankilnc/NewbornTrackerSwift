import Foundation
import SwiftData

/// A vaccine as the list shows it.
struct VaccineRow: Identifiable, Equatable {
    let source: ChecklistSource
    let name: String
    let ageLabel: String
    let isDone: Bool

    var id: String { source.id }
}

enum VaccineChecklist {
    /// The parent's own vaccines first (oldest first), then the built-in schedule.
    static func rows(
        completedIDs: Set<String>,
        customVaccines: [CustomVaccine],
        schedule: [ScheduleItem] = VaccineSchedule.items
    ) -> [VaccineRow] {
        let custom = customVaccines
            .sorted { $0.createdAt < $1.createdAt }
            .map { vaccine in
                VaccineRow(
                    source: .custom(vaccine.id),
                    name: vaccine.name,
                    ageLabel: vaccine.ageLabel ?? "",
                    isDone: vaccine.isCompleted
                )
            }

        let scheduled = schedule.map { item in
            VaccineRow(
                source: .scheduled(item.id),
                name: String(localized: item.name),
                ageLabel: String(localized: item.age),
                isDone: completedIDs.contains(item.id)
            )
        }

        return custom + scheduled
    }

    static func progress(of rows: [VaccineRow]) -> (done: Int, total: Int) {
        (rows.filter(\.isDone).count, rows.count)
    }
}

extension ModelContext {
    /// Marks a vaccine done, or takes the mark away.
    func toggleVaccine(_ source: ChecklistSource, for baby: Baby) {
        switch source {
        case .scheduled(let scheduleID):
            if let completion = baby.vaccineCompletions.first(where: { $0.scheduleID == scheduleID }) {
                delete(completion)
            } else {
                let completion = VaccineCompletion(scheduleID: scheduleID)
                insert(completion)
                completion.baby = baby
            }
        case .custom(let id):
            baby.customVaccines.first(where: { $0.id == id })?.isCompleted.toggle()
        }
    }
}
