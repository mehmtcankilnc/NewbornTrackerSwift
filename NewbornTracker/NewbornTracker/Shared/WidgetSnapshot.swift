import Foundation
import SwiftData

/// Everything the home screen widget shows, as plain values. The widget draws it and never touches the database.
nonisolated struct WidgetSnapshot: Equatable {
    var babyID: UUID?
    var babyName: String?
    private(set) var counts: [RecordType: Int] = [:]
    var sleepMinutesToday = 0
    /// When the running sleep started. Nil when the baby is awake.
    var sleepStartedAt: Date?

    static let empty = WidgetSnapshot()

    init() {}

    init(
        babyID: UUID,
        babyName: String,
        records: [RecordValue],
        sleepStartedAt: Date?,
        now: Date = .now,
        calendar: Calendar = .current
    ) {
        self.babyID = babyID
        self.babyName = babyName
        self.sleepStartedAt = sleepStartedAt

        for record in records where calendar.isDate(record.occurredAt, inSameDayAs: now) {
            counts[record.type, default: 0] += 1
            if record.type == .sleep {
                sleepMinutesToday += record.durationMinutes ?? 0
            }
        }
    }

    func count(for type: RecordType) -> Int { counts[type, default: 0] }
}

/// Reads the database for the widget. It has its own ModelContext, like RecordService.
@ModelActor
actor WidgetDataService {
    /// The snapshot for the active baby, or for the first baby when none is selected.
    func snapshot(activeBabyID: UUID?, now: Date = .now) throws -> WidgetSnapshot {
        let babies = try modelContext.fetch(FetchDescriptor<Baby>(sortBy: [SortDescriptor(\.createdAt)]))
        guard let baby = babies.first(where: { $0.id == activeBabyID }) ?? babies.first else { return .empty }

        let startOfDay = Calendar.current.startOfDay(for: now)
        let babyID = baby.id
        let records = try modelContext.fetch(FetchDescriptor<BabyRecord>(
            predicate: #Predicate { $0.baby?.id == babyID && $0.occurredAt >= startOfDay }
        ))

        return WidgetSnapshot(
            babyID: baby.id,
            babyName: baby.name,
            records: records.map(RecordValue.init),
            sleepStartedAt: baby.activeSleep?.startedAt,
            now: now
        )
    }
}
