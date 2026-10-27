import Foundation

nonisolated struct RecordValue: Identifiable, Equatable, Sendable {
    let id: UUID
    var type: RecordType
    var occurredAt: Date
    var endedAt: Date?
    var durationMinutes: Int?

    init(
        id: UUID = UUID(),
        type: RecordType,
        occurredAt: Date,
        endedAt: Date? = nil,
        durationMinutes: Int? = nil
    ) {
        self.id = id
        self.type = type
        self.occurredAt = occurredAt
        self.endedAt = endedAt
        self.durationMinutes = durationMinutes
    }

    init(_ record: BabyRecord) {
        self.init(
            id: record.id,
            type: record.type,
            occurredAt: record.occurredAt,
            endedAt: record.endedAt,
            durationMinutes: record.durationMinutes
        )
    }
}
