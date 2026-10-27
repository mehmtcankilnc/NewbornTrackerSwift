import SwiftUI

/// A compact "Today ⌄" style button that opens a sheet.
struct FilterTrigger: View {
    let symbol: String
    let title: String
    var isActive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .scaledFont(size: 13)
                    .foregroundStyle(isActive ? Color.white : Color.appMuted)
                Text(title)
                    .scaledFont(size: 12, weight: .semibold)
                    .foregroundStyle(isActive ? Color.white : Color.appInk)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .scaledFont(size: 11)
                    .foregroundStyle(isActive ? Color.white : Color.appMuted)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 36)
            .background(isActive ? Color.appPrimary : Color.appSurfaceElevated, in: .capsule)
            .overlay(Capsule().stroke(isActive ? Color.appPrimary : Color.appBorder, lineWidth: 1))
        }
        .buttonStyle(.pressableScale)
    }
}

/// An applied filter shown below the bar. Tapping it removes the filter.
struct RemovableChip: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .scaledFont(size: 12, weight: .semibold)
                    .lineLimit(1)
                Image(systemName: "xmark")
                    .scaledFont(size: 10, weight: .bold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(minHeight: 36)
            .background(Color.appPrimary, in: .capsule)
        }
        .buttonStyle(.pressableScale)
    }
}
