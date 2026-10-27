import Foundation

enum SleepTimer {
    static func elapsedMinutes(of sleep: ActiveSleep, now: Date = .now) -> Int {
        max(0, minutes(from: sleep.startedAt, to: now))
    }

    /// The record to save when a sleep ends. A sleep always lasts at least one minute.
    static func finishedDraft(for sleep: ActiveSleep, endedAt: Date = .now) -> RecordDraft {
        RecordDraft(
            type: .sleep,
            occurredAt: sleep.startedAt,
            endedAt: endedAt,
            durationMinutes: max(1, minutes(from: sleep.startedAt, to: endedAt))
        )
    }

    private static func minutes(from start: Date, to end: Date) -> Int {
        Int((end.timeIntervalSince(start) / 60).rounded())
    }
}
