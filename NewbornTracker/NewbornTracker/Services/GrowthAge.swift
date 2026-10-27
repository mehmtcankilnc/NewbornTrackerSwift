import Foundation

enum GrowthAge {
    /// The WHO's average month: 365.25 days / 12.
    static let daysPerMonth = 30.4375

    /// Age in fractional months at `date`. Never negative, so a date before the birth counts as 0.
    static func months(from birthDate: Date, to date: Date) -> Double {
        let days = date.timeIntervalSince(birthDate) / 86_400
        return max(0, days / daysPerMonth)
    }
}
