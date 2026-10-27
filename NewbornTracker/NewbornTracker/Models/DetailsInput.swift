import Foundation

/// The feed details form: at least one subtype, optional amount in ml.
struct FeedDetailsInput: Equatable {
    var subtypes: Set<FeedSubtype> = []
    var amountText = ""

    var amountMl: Int? {
        guard let value = Int(amountText.trimmingCharacters(in: .whitespaces)), value > 0 else { return nil }
        return value
    }

    var canSave: Bool { !subtypes.isEmpty }

    mutating func toggle(_ subtype: FeedSubtype) {
        if subtypes.contains(subtype) {
            subtypes.remove(subtype)
        } else {
            subtypes.insert(subtype)
        }
    }

    func draft(at occurredAt: Date) -> RecordDraft? {
        guard canSave else { return nil }
        return RecordDraft(
            type: .feed,
            occurredAt: occurredAt,
            feedSubtypes: FeedSubtype.allCases.filter(subtypes.contains),
            amountMl: amountMl
        )
    }
}

/// The health details form: fever needs a temperature, medicine and vitamin need a note.
struct HealthDetailsInput: Equatable {
    let type: RecordType
    var temperatureText = ""
    var noteText = ""

    var temperatureC: Double? {
        let normalized = temperatureText
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        guard let value = Double(normalized), value.isFinite, value > 0 else { return nil }
        return value
    }

    var note: String? {
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var canSave: Bool { type == .fever ? temperatureC != nil : note != nil }

    func draft(at occurredAt: Date) -> RecordDraft? {
        guard canSave else { return nil }
        if type == .fever {
            return RecordDraft(type: type, occurredAt: occurredAt, temperatureC: temperatureC)
        }
        return RecordDraft(type: type, occurredAt: occurredAt, note: note)
    }
}
