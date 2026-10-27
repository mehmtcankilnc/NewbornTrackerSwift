import SwiftData

enum AppSchema {
    static let appGroupID = "group.com.mehmtcan.NewbornTracker"
    static let activeBabyDefaultsKey = "activeBabyID"
    
    static let models: [any PersistentModel.Type] = [
        Baby.self,
        BabyRecord.self,
        GrowthMeasurement.self,
        VaccineCompletion.self,
        CustomVaccine.self,
        MilestoneEntry.self,
        CustomMilestone.self,
    ]
    
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        try ModelContainer(
            for: Schema(models),
            configurations: ModelConfiguration(
                isStoredInMemoryOnly: inMemory,
                groupContainer: .identifier(appGroupID)
            )
        )
    }
}
