import Foundation

/// How many records of each type were logged today, plus total sleep time.
struct TodayStats: Equatable {
    private(set) var counts: [RecordType: Int] = [:]
    private(set) var sleepMinutes = 0

    init<Record: LoggedRecord>(records: [Record], now: Date = .now, calendar: Calendar = .current) {
        for record in records where calendar.isDate(record.occurredAt, inSameDayAs: now) {
            counts[record.type, default: 0] += 1

            if record.type == .sleep {
                sleepMinutes += record.durationMinutes ?? 0
            }
        }
    }

    func count(for type: RecordType) -> Int {
        counts[type, default: 0]
    }
}
