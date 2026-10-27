import Foundation

/// How many records of one type happened on one day: the one bar the chart draws.
struct ChartPoint: Identifiable, Equatable {
    let day: Date
    let type: RecordType
    let count: Int

    var id: String { "\(day.timeIntervalSinceReferenceDate)-\(type.rawValue)" }
}

enum ChartData {
    /// One point per day and per requested type, days oldest first.
    /// Types with no record that day still get a point (count 0), so every day has the same bar slots.
    static func points<Record: LoggedRecord>(
        from records: [Record],
        types: [RecordType],
        calendar: Calendar = .current
    ) -> [ChartPoint] {
        let recordsByDay = Dictionary(grouping: records) { record in
            calendar.startOfDay(for: record.occurredAt)
        }

        return recordsByDay.keys.sorted().flatMap { day in
            types.map { type in
                let count = recordsByDay[day, default: []].filter { $0.type == type }.count
                return ChartPoint(day: day, type: type, count: count)
            }
        }
    }

    /// The types to draw: the filtered ones, or the four main ones when nothing is filtered.
    static func types(for filter: RecordFilter) -> [RecordType] {
        filter.types.isEmpty ? RecordType.primary : RecordType.allCases.filter(filter.types.contains)
    }
}
