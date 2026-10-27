import SwiftData
import SwiftUI
import UserNotifications

@main
struct NewbornTrackerApp: App {
    private let container: ModelContainer
    private let notificationDelegate: NotificationDelegate
    @State private var activeBabyStore = ActiveBabyStore()
    @State private var router: AppRouter

    init() {
        let container: ModelContainer
        do {
            container = try AppSchema.makeContainer()
        } catch {
            fatalError("Could not create the model container: \(error)")
        }
        let router = AppRouter()

        self.container = container
        self._router = State(initialValue: router)
        self.notificationDelegate = NotificationDelegate(router: router, container: container)

        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories([SleepNotification.makeCategory()])
        center.delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(activeBabyStore)
                .environment(router)
        }
        .modelContainer(container)
    }
}
