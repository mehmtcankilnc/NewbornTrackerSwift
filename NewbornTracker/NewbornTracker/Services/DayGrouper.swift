import Foundation

/// All records that happened on one calendar day, newest first.
struct DaySection<Record: LoggedRecord>: Identifiable {
    /// Midnight at the start of this day, in the calendar used for grouping.
    let day: Date
    let records: [Record]

    var id: Date { day }
}

extension DaySection: Equatable where Record: Equatable {}

/// What to call a day in a section header. Turning it into text is the view's job.
enum DayHeading: Equatable {
    case today
    case yesterday
    case date(Date)
}

enum DayGrouper {
    /// Groups records by calendar day. Days are newest first, and so are records within a day.
    static func group<Record: LoggedRecord>(_ records: [Record], calendar: Calendar = .current) -> [DaySection<Record>] {
        let recordsByDay = Dictionary(grouping: records) { record in
            calendar.startOfDay(for: record.occurredAt)
        }

        return recordsByDay
            .map { day, records in
                DaySection(day: day, records: records.sorted { $0.occurredAt > $1.occurredAt })
            }
            .sorted { $0.day > $1.day }
    }

    static func heading(for day: Date, now: Date = .now, calendar: Calendar = .current) -> DayHeading {
        if calendar.isDate(day, inSameDayAs: now) {
            return .today
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(day, inSameDayAs: yesterday) {
            return .yesterday
        }
        return .date(day)
    }
}
