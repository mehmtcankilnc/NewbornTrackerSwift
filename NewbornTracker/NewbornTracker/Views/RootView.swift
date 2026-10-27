import SwiftData
import SwiftUI

/// Chooses between the first-launch flow and the app.
/// Someone who already has a baby never sees onboarding, even if the flag was never set.
struct RootView: View {
    @Query private var babies: [Baby]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding || !babies.isEmpty {
            ContentView()
        } else {
            OnboardingView { hasCompletedOnboarding = true }
        }
    }
}
