import SwiftUI

/// A small "push" on press, used by every tappable card, row and button.
struct PressableScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableScaleStyle {
    static var pressableScale: PressableScaleStyle { PressableScaleStyle() }
}
