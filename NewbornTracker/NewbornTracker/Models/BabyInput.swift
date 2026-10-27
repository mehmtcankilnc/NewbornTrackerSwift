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
    
    /// Writes the form back to a saved baby. Does nothing while the name is blank.
    func apply(to baby: Baby) {
        guard canSave else { return }
        baby.name = trimmedName
        baby.birthDate = hasBirthDate ? birthDate : nil
        baby.gender = gender
    }
}

extension BabyInput {
    /// An edit form that starts with the saved profile.
    /// It lives in an extension so the struct keeps its automatic memberwise initializer.
    init(_ baby: Baby) {
        self.init(
            name: baby.name,
            hasBirthDate: baby.birthDate != nil,
            birthDate: baby.birthDate ?? .now,
            gender: baby.gender
        )
    }
}
