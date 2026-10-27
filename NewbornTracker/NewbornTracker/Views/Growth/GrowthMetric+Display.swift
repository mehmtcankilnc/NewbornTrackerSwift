import Foundation

extension GrowthMetric {
    var title: LocalizedStringResource {
        switch self {
        case .weight: "Weight"
        case .height: "Height"
        case .headCircumference: "Head circumference"
        }
    }

    /// Short enough for a three-way segmented control.
    var shortTitle: LocalizedStringResource {
        switch self {
        case .weight: "Weight"
        case .height: "Height"
        case .headCircumference: "Head"
        }
    }

    /// "kg" or "cm", as the system writes it.
    var unitSymbol: String {
        switch self {
        case .weight: UnitMass.kilograms.symbol
        case .height, .headCircumference: UnitLength.centimeters.symbol
        }
    }

    /// The value with its unit, in the user's number format: "4.25 kg".
    func formatted(_ value: Double) -> String {
        switch self {
        case .weight:
            Measurement(value: value, unit: UnitMass.kilograms)
                .formatted(.measurement(width: .abbreviated, usage: .asProvided))
        case .height, .headCircumference:
            Measurement(value: value, unit: UnitLength.centimeters)
                .formatted(.measurement(width: .abbreviated, usage: .asProvided))
        }
    }
}
