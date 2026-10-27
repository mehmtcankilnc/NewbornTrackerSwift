import SwiftUI

/// A tappable checklist row: something on the left, a title, and a subtitle.
struct ChecklistRow<Leading: View>: View {
    let title: String
    let subtitle: String
    let isDone: Bool
    let action: () -> Void
    @ViewBuilder let leading: Leading

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                leading
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .scaledFont(size: 14, weight: .semibold)
                        .foregroundStyle(isDone ? Color.appMuted : Color.appInk)
                        .strikethrough(isDone)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .scaledFont(size: 12)
                            .foregroundStyle(Color.appMuted)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(cornerRadius: 16, shadowRadius: 3, shadowY: 1)
        }
        .buttonStyle(.pressableScale)
        .accessibilityAddTraits(isDone ? .isSelected : [])
    }
}

/// The round tick used on checklist rows.
struct CheckCircle: View {
    let isDone: Bool

    var body: some View {
        Circle()
            .fill(isDone ? Color.appPrimary : Color.clear)
            .overlay(Circle().stroke(isDone ? Color.appPrimary : Color.appBorder, lineWidth: 2))
            .overlay {
                if isDone {
                    Image(systemName: "checkmark")
                        .scaledFont(size: 12, weight: .bold)
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 24, height: 24)
    }
}
