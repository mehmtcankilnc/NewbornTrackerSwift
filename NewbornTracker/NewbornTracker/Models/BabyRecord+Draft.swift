import Foundation
import SwiftData

extension BabyRecord {
    convenience init(_ draft: RecordDraft) {
        self.init(
            type: draft.type,
            occurredAt: draft.occurredAt,
            endedAt: draft.endedAt,
            durationMinutes: draft.durationMinutes,
            feedSubtypes: draft.feedSubtypes,
            amountMl: draft.amountMl,
            temperatureC: draft.temperatureC,
            note: draft.note
        )
    }
}

extension ModelContext {
    @discardableResult
    func insertRecord(_ draft: RecordDraft, for baby: Baby) -> BabyRecord {
        let record = BabyRecord(draft)
        insert(record)
        record.baby = baby
        return record
    }

    /// Ends the baby's active sleep and saves it as a record. Nil when no sleep is running.
    @discardableResult
    func finishSleep(of baby: Baby, endedAt: Date = .now) -> BabyRecord? {
        guard let sleep = baby.activeSleep else { return nil }
        baby.activeSleep = nil
        return insertRecord(SleepTimer.finishedDraft(for: sleep, endedAt: endedAt), for: baby)
    }
}
