import Foundation

struct RecordFilter: Equatable {
    /// An empty set means "all types".
    var types: Set<RecordType> = []
    var period: Period = .today

    var isActive: Bool { !types.isEmpty || period != .all }

    func matches(_ record: some LoggedRecord, now: Date = .now, calendar: Calendar = .current) -> Bool {
        (types.isEmpty || types.contains(record.type))
            && period.contains(record.occurredAt, now: now, calendar: calendar)
    }

    func apply<Record: LoggedRecord>(to records: [Record], now: Date = .now, calendar: Calendar = .current) -> [Record] {
        records.filter { matches($0, now: now, calendar: calendar) }
    }
}
