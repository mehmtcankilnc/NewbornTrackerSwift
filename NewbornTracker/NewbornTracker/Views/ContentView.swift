import SwiftUI
import WidgetKit

enum AppTab: Hashable {
    case home, records, growth
}

struct ContentView: View {
    @State private var selectedTab = AppTab.home
    @Environment(AppRouter.self) private var router
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var router = router

        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: AppTab.home) {
                HomeView()
            }
            Tab("Records", systemImage: "list.bullet", value: AppTab.records) {
                RecordsView { selectedTab = .home }
            }
            Tab("Growth", systemImage: "chart.line.uptrend.xyaxis", value: AppTab.growth) {
                GrowthView()
            }
        }
        .tint(Color.appPrimary)
        .onChange(of: scenePhase) { _, phase in
            // Leaving the app is the moment to refresh the widget with whatever changed.
            if phase == .background {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        .sheet(isPresented: $router.isShowingSettings) {
            SettingsView()
        }
        .onChange(of: router.pendingRoute) { _, route in
            if route != nil {
                selectedTab = .home
            }
        }
    }
}
