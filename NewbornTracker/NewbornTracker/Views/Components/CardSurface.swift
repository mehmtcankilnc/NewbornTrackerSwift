import SwiftUI

private struct CardSurface: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let shadowY: CGFloat

    func body(content: Content) -> some View {
        content
            .background(Color.appCard, in: .rect(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.35 : 0.08), radius: shadowRadius, y: shadowY)
    }
}

extension View {
    /// The app's raised surface: neutral fill with a soft shadow, no border.
    func cardSurface(cornerRadius: CGFloat = 20, shadowRadius: CGFloat = 8, shadowY: CGFloat = 2) -> some View {
        modifier(CardSurface(cornerRadius: cornerRadius, shadowRadius: shadowRadius, shadowY: shadowY))
    }
}
