import Foundation

/// A validated record that is about to be saved. Plain values, so forms and flows can be
/// tested without SwiftData.
struct RecordDraft: Equatable {
    var type: RecordType
    var occurredAt: Date
    var endedAt: Date?
    var durationMinutes: Int?
    var feedSubtypes: [FeedSubtype] = []
    var amountMl: Int?
    var temperatureC: Double?
    var note: String?
}
