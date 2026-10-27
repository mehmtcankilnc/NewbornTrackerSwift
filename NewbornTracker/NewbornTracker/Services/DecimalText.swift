import Foundation

enum DecimalText {
    /// A positive number from what the user typed. "4,25" and "4.25" both work,
    /// because the decimal keyboard follows the device language.
    static func positiveValue(_ text: String) -> Double? {
        let normalized = text
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        guard let value = Double(normalized), value.isFinite, value > 0 else { return nil }
        return value
    }
}
