import Observation

/// Where the app should go next, set by things outside the view tree such as a notification tap.
@Observable
final class AppRouter {
    enum Route: Equatable {
        case stopSleep
    }

    var pendingRoute: Route?
    var isShowingSettings = false
}
