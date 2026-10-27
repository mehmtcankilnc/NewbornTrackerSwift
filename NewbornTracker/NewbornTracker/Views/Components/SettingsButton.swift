import SwiftUI

/// The round gear button in screen headers. It asks the router to open Settings.
struct SettingsButton: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        Button {
            router.isShowingSettings = true
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 16))
                .foregroundStyle(Color.appInk)
                .frame(width: 36, height: 36)
                .background(Color.appSurfaceElevated, in: .circle)
        }
        .buttonStyle(.pressableScale)
        .accessibilityLabel("Settings")
    }
}
