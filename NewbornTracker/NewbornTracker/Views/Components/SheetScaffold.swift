import SwiftUI

/// Shared bottom-sheet content: a title, the content, and a height that fits what is inside.
/// Content taller than the screen scrolls.
struct SheetScaffold<Content: View>: View {
    let title: LocalizedStringResource
    @ViewBuilder let content: Content

    @State private var contentHeight: CGFloat = 420

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(String(localized: title))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.appInk)
                content
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .presentationDetents([.height(contentHeight)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.appSurfaceOverlay)
    }
}
