import Foundation
import SwiftData

@Model
final class GrowthMeasurement {
    var id: UUID
    var date: Date
    var weightKg: Double?
    var heightCm: Double?
    var headCircumferenceCm: Double?
    var baby: Baby?

    init(date: Date, weightKg: Double? = nil, heightCm: Double? = nil, headCircumferenceCm: Double? = nil) {
        self.id = UUID()
        self.date = date
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.headCircumferenceCm = headCircumferenceCm
    }
}
