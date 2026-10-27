import SwiftUI

struct StatCard: View {
    let title: LocalizedStringResource
    let symbol: String
    let accent: Color
    let value: String
    var unit: LocalizedStringResource?
    var subtitle: String?
    var topRight: String?
    var showsDot = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(String(localized: title), systemImage: symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(accent)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    if let topRight {
                        Text(topRight)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.appMuted)
                    }
                }

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(value)
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(Color.appInk)
                                .lineLimit(1)
                            if let unit {
                                Text(String(localized: unit))
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.appMuted)
                            }
                        }
                        if let subtitle {
                            Text(subtitle)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.appMuted)
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 0)
                    if showsDot {
                        BreathingDot(color: accent)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface()
        }
        .buttonStyle(.pressableScale)
    }
}

/// A slow pulse that marks a sleep still in progress. The only looping animation in the app.
private struct BreathingDot: View {
    let color: Color
    @State private var isBright = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .opacity(isBright ? 1 : 0.45)
            .scaleEffect(isBright ? 1 : 0.85)
            .padding(.bottom, 6)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    isBright = true
                }
            }
    }
}
