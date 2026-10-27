import Foundation

/// The "add / edit measurement" form. All three values are optional, but at least one is needed.
struct GrowthEntryInput: Equatable {
    var date: Date
    var weightText = ""
    var heightText = ""
    var headText = ""

    init(date: Date = .now) {
        self.date = date
    }

    /// An edit form that starts with the saved values.
    init(_ measurement: GrowthMeasurement) {
        date = measurement.date
        weightText = measurement.weightKg.map { String($0) } ?? ""
        heightText = measurement.heightCm.map { String($0) } ?? ""
        headText = measurement.headCircumferenceCm.map { String($0) } ?? ""
    }

    var weightKg: Double? { DecimalText.positiveValue(weightText) }
    var heightCm: Double? { DecimalText.positiveValue(heightText) }
    var headCircumferenceCm: Double? { DecimalText.positiveValue(headText) }

    var canSave: Bool { weightKg != nil || heightCm != nil || headCircumferenceCm != nil }

    func makeMeasurement() -> GrowthMeasurement? {
        guard canSave else { return nil }
        return GrowthMeasurement(
            date: date,
            weightKg: weightKg,
            heightCm: heightCm,
            headCircumferenceCm: headCircumferenceCm
        )
    }

    /// Writes all three values back. A cleared field clears the saved value too.
    func apply(to measurement: GrowthMeasurement) {
        measurement.date = date
        measurement.weightKg = weightKg
        measurement.heightCm = heightCm
        measurement.headCircumferenceCm = headCircumferenceCm
    }
}
