import SwiftData
import SwiftUI

@main
struct NewbornTrackerApp: App {
    private let container: ModelContainer
    @State private var activeBabyStore = ActiveBabyStore()

    init() {
        do {
            container = try AppSchema.makeContainer()
        } catch {
            fatalError("Could not create the model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(activeBabyStore)
        }
        .modelContainer(container)
    }
}
