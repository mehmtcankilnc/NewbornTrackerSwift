import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                DebugDataView()
            }
            Tab("Records", systemImage: "list.bullet") {
                Text("Records")
            }
            Tab("Growth", systemImage: "chart.line.uptrend.xyaxis") {
                Text("Growth")
            }
        }
        .tint(Color.appPrimary)
    }
}

/// Temporary swatch screen to eyeball the theme. Removed in Phase 3.
struct ThemePreviewView: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(RecordType.allCases) { type in
                Text(type.rawValue.capitalized)
                    .font(.headline)
                    .foregroundStyle(type.accent)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(type.accentBackground, in: .rect(cornerRadius: 12))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appSurface)
    }
}

#Preview("Light") {
    ContentView()
}

#Preview("Dark") {
    ContentView().preferredColorScheme(.dark)
}
