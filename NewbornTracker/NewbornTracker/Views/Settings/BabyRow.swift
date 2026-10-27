import SwiftUI

/// One baby in the Settings list. The active baby is filled.
struct BabyRow: View {
    let baby: Baby
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "person.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(isActive ? Color.white : Color.appMuted)
                    .frame(width: 36, height: 36)
                    .background(isActive ? Color.white.opacity(0.2) : Color.appSurface, in: .circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text(baby.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isActive ? Color.white : Color.appInk)
                    if let birthDate = baby.birthDate {
                        Text(birthDate.formatted(.dateTime.day().month(.wide).year()))
                            .font(.system(size: 12))
                            .foregroundStyle(isActive ? Color.white.opacity(0.8) : Color.appMuted)
                    }
                }
                Spacer()
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(isActive ? Color.appPrimary : Color.appSurfaceElevated, in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.pressableScale)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}
