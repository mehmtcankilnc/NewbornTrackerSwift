import Foundation

/// The edit form of a saved record. Equatable, so "did anything change?" is one comparison.
struct RecordEditInput: Equatable {
    let type: RecordType
    var occurredAt: Date
    var feed: FeedDetailsInput
    var health: HealthDetailsInput

    init(_ record: BabyRecord) {
        type = record.type
        occurredAt = record.occurredAt
        feed = FeedDetailsInput(
            subtypes: Set(record.feedSubtypes),
            amountText: record.amountMl.map(String.init) ?? ""
        )
        health = HealthDetailsInput(
            type: record.type,
            temperatureText: record.temperatureC.map { String($0) } ?? "",
            noteText: record.note ?? ""
        )
    }

    var detailsAreValid: Bool {
        switch type {
        case .feed: feed.canSave
        case .fever, .medicine, .vitamin: health.canSave
        case .poop, .piss, .sleep: true
        }
    }

    /// Writes the fields that belong to this record's type back to the record.
    func apply(to record: BabyRecord) {
        record.occurredAt = occurredAt

        switch type {
        case .feed:
            record.feedSubtypes = FeedSubtype.allCases.filter(feed.subtypes.contains)
            record.amountMl = feed.amountMl
        case .fever:
            record.temperatureC = health.temperatureC
        case .medicine, .vitamin:
            record.note = health.note
        case .poop, .piss, .sleep:
            break
        }
    }
}
