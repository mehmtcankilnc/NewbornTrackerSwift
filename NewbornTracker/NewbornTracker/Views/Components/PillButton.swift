import SwiftUI

struct PillButton: View {
    enum Style {
        case primary, secondary, destructive
    }

    let title: LocalizedStringKey
    var style: Style = .primary
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(style == .secondary ? Color.appInk : .white)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(fill, in: .capsule)
                .overlay {
                    if style == .secondary {
                        Capsule().stroke(Color.appBorder, lineWidth: 1)
                    }
                }
                .opacity(isEnabled ? 1 : 0.4)
        }
        .buttonStyle(.pressableScale)
    }

    private var fill: Color {
        switch style {
        case .primary: .appPrimary
        case .secondary: .appSurfaceElevated
        case .destructive: .appDanger
        }
    }
}

/// A selectable row used in the sheets: filled when selected, with a checkmark.
struct OptionPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundStyle(isSelected ? Color.white : Color.appInk)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(isSelected ? Color.appPrimary : Color.appSurfaceElevated, in: .capsule)
        }
        .buttonStyle(.pressableScale)
    }
}

/// A labeled text field in the pill shape used across the sheets.
struct PillTextField: View {
    let title: LocalizedStringKey
    let placeholder: LocalizedStringKey
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.appMuted)
            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .font(.system(size: 16))
                .foregroundStyle(Color.appInk)
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(Color.appSurfaceElevated, in: .capsule)
        }
    }
}
