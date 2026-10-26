import Foundation
import SwiftData

@Model
final class CustomVaccine {
    var id: UUID
    var name: String
    var ageLabel: String?
    var isCompleted: Bool
    var baby: Baby?

    init(name: String, ageLabel: String? = nil, isCompleted: Bool = false) {
        self.id = UUID()
        self.name = name
        self.ageLabel = ageLabel
        self.isCompleted = isCompleted
    }
}
