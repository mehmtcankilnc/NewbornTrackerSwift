import Foundation

/// The second line of a record row. Turning it into text is the view's job.
enum RecordDetail: Equatable {
    case sleep(minutes: Int, endedAt: Date?)
    case feed(subtypes: [FeedSubtype], amountMl: Int?)
    case fever(Double)
    case note(String)

    init?(_ record: BabyRecord) {
        switch record.type {
        case .sleep:
            guard let minutes = record.durationMinutes else { return nil }
            self = .sleep(minutes: minutes, endedAt: record.endedAt)
        case .feed:
            guard !record.feedSubtypes.isEmpty else { return nil }
            self = .feed(subtypes: record.feedSubtypes, amountMl: record.amountMl)
        case .fever:
            guard let temperature = record.temperatureC else { return nil }
            self = .fever(temperature)
        case .medicine, .vitamin:
            guard let note = record.note, !note.isEmpty else { return nil }
            self = .note(note)
        case .poop, .piss:
            return nil
        }
    }
}

/// How many feeds of each subtype a day had. A feed with two subtypes counts for both.
struct FeedBreakdown: Equatable {
    struct Entry: Equatable {
        let subtype: FeedSubtype
        let count: Int
    }

    let entries: [Entry]
    /// Feeds saved without any subtype.
    let untyped: Int

    init(records: [BabyRecord]) {
        entries = FeedSubtype.allCases.compactMap { subtype in
            let count = records.count { $0.feedSubtypes.contains(subtype) }
            return count > 0 ? Entry(subtype: subtype, count: count) : nil
        }
        untyped = records.count { $0.feedSubtypes.isEmpty }
    }
}

/// The small label on the right of a day header. Only shown while a type filter is active.
enum DaySummary: Equatable {
    case none
    case count(Int)
    case feedBreakdown(FeedBreakdown)

    init(records: [BabyRecord], filter: RecordFilter) {
        if filter.types.isEmpty {
            self = .none
        } else if filter.types == [.feed] {
            self = .feedBreakdown(FeedBreakdown(records: records))
        } else {
            self = .count(records.count)
        }
    }
}
