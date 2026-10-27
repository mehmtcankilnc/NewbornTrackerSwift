import SwiftUI

enum AppTab: Hashable {
    case home, records, growth
}

struct ContentView: View {
    @State private var selectedTab = AppTab.home
    @Environment(AppRouter.self) private var router

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: AppTab.home) {
                HomeView()
            }
            Tab("Records", systemImage: "list.bullet", value: AppTab.records) {
                RecordsView { selectedTab = .home }
            }
            Tab("Growth", systemImage: "chart.line.uptrend.xyaxis", value: AppTab.growth) {
                Text("Growth")
            }
        }
        .tint(Color.appPrimary)
        .onChange(of: router.pendingRoute) { _, route in
            if route != nil {
                selectedTab = .home
            }
        }
    }
}
