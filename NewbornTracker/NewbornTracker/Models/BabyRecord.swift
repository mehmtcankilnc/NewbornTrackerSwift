import Foundation
import SwiftData

@Model
final class BabyRecord {
    var id: UUID
    var type: RecordType
    var occurredAt: Date
    var createdAt: Date
    var endedAt: Date?
    var durationMinutes: Int?
    var feedSubtypes: [FeedSubtype]
    var amountMl: Int?
    var temperatureC: Double?
    var note: String?
    var baby: Baby?

    init(
        type: RecordType,
        occurredAt: Date,
        createdAt: Date = .now,
        endedAt: Date? = nil,
        durationMinutes: Int? = nil,
        feedSubtypes: [FeedSubtype] = [],
        amountMl: Int? = nil,
        temperatureC: Double? = nil,
        note: String? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.occurredAt = occurredAt
        self.createdAt = createdAt
        self.endedAt = endedAt
        self.durationMinutes = durationMinutes
        self.feedSubtypes = feedSubtypes
        self.amountMl = amountMl
        self.temperatureC = temperatureC
        self.note = note
    }
}
