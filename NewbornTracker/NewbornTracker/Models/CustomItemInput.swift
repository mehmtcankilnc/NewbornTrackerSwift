import Foundation

/// The "add your own" form, shared by custom vaccines and custom milestones: a name and an optional age text.
struct CustomItemInput: Equatable {
    var name = ""
    var ageText = ""

    init() {}

    init(name: String, ageLabel: String?) {
        self.name = name
        ageText = ageLabel ?? ""
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var ageLabel: String? {
        let trimmed = ageText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var canSave: Bool { !trimmedName.isEmpty }

    func makeVaccine() -> CustomVaccine? {
        guard canSave else { return nil }
        return CustomVaccine(name: trimmedName, ageLabel: ageLabel)
    }

    func makeMilestone() -> CustomMilestone? {
        guard canSave else { return nil }
        return CustomMilestone(name: trimmedName, ageLabel: ageLabel)
    }

    func apply(to vaccine: CustomVaccine) {
        vaccine.name = trimmedName
        vaccine.ageLabel = ageLabel
    }
}
