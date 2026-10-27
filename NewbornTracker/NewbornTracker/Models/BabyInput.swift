import Foundation

/// The "add a baby" form.
struct BabyInput: Equatable {
    var name = ""
    var hasBirthDate = false
    var birthDate = Date.now
    var gender: Gender?

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool { !trimmedName.isEmpty }

    func makeBaby(createdAt: Date = .now) -> Baby? {
        guard canSave else { return nil }
        return Baby(
            name: trimmedName,
            birthDate: hasBirthDate ? birthDate : nil,
            gender: gender,
            createdAt: createdAt
        )
    }
}
