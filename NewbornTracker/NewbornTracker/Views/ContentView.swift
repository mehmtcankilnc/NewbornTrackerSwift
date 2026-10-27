import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                HomeView()
            }
            Tab("Records", systemImage: "list.bullet") { Text("Records") }
            Tab("Growth", systemImage: "chart.line.uptrend.xyaxis") { Text("Growth") }
        }
        .tint(Color.appPrimary)
    }
}
