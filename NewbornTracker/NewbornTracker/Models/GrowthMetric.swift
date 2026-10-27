/// The three things we measure. Also the key into the WHO table.
enum GrowthMetric: String, CaseIterable, Identifiable {
    case weight, height, headCircumference

    var id: String { rawValue }

    /// Reads this metric out of a measurement. Nil when that value was not entered.
    func value(in measurement: GrowthMeasurement) -> Double? {
        switch self {
        case .weight: measurement.weightKg
        case .height: measurement.heightCm
        case .headCircumference: measurement.headCircumferenceCm
        }
    }
}
