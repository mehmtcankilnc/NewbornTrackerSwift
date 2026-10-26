import Foundation
import SwiftData

enum RecordServiceError: Error {
    case babyNotFound
}

/// Reads and writes records off the main actor. It owns its own ModelContext.
@ModelActor
actor RecordService {
    func addRecord(type: RecordType, occurredAt: Date, babyID: UUID) throws -> RecordValue {
        let babies = try modelContext.fetch(FetchDescriptor<Baby>(predicate: #Predicate { $0.id == babyID }))
        guard let baby = babies.first else { throw RecordServiceError.babyNotFound }

        let record = BabyRecord(type: type, occurredAt: occurredAt)
        modelContext.insert(record)
        record.baby = baby
        try modelContext.save()

        return RecordValue(record)
    }
}
