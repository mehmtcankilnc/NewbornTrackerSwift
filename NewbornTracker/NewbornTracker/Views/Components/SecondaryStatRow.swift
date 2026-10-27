import SwiftUI

/// The Home screen's quieter second tier: status you glance at, not an action you repeat all day.
struct SecondaryStatRow: View {
    let title: LocalizedStringResource
    let symbol: String
    let accent: Color
    let value: String
    var subtitle: String?
    var showsChevron = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 17))
                    .foregroundStyle(accent)
                    .frame(width: 40, height: 40)
                    .background(accent.opacity(0.1), in: .circle)

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: title))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.appInk)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appMuted)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                HStack(spacing: 6) {
                    Text(value)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.appInk)
                    if showsChevron {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.appMuted)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .cardSurface(cornerRadius: 16, shadowRadius: 4, shadowY: 1)
        }
        .buttonStyle(.pressableScale)
    }
}
