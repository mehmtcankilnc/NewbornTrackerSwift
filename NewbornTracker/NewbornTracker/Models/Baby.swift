import Foundation
import SwiftData

@Model
final class Baby {
    var id: UUID
    var name: String
    var birthDate: Date?
    var gender: Gender?
    var createdAt: Date
    var activeSleep: ActiveSleep?

    @Relationship(deleteRule: .cascade, inverse: \BabyRecord.baby)
    var records: [BabyRecord] = []
    
    @Relationship(deleteRule: .cascade, inverse: \GrowthMeasurement.baby)
    var measurements: [GrowthMeasurement] = []

    @Relationship(deleteRule: .cascade, inverse: \VaccineCompletion.baby)
    var vaccineCompletions: [VaccineCompletion] = []

    @Relationship(deleteRule: .cascade, inverse: \CustomVaccine.baby)
    var customVaccines: [CustomVaccine] = []

    @Relationship(deleteRule: .cascade, inverse: \MilestoneEntry.baby)
    var milestoneEntries: [MilestoneEntry] = []

    @Relationship(deleteRule: .cascade, inverse: \CustomMilestone.baby)
    var customMilestones: [CustomMilestone] = []

    init(name: String, birthDate: Date? = nil, gender: Gender? = nil, createdAt: Date = .now) {
        self.id = UUID()
        self.name = name
        self.birthDate = birthDate
        self.gender = gender
        self.createdAt = createdAt
    }
}
