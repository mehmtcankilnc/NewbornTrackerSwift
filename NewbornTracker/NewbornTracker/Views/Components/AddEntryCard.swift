import SwiftUI

/// A card that invites the user to add something: icon badge, title, hint and a chevron.
struct AddEntryCard: View {
    let symbol: String
    let title: LocalizedStringKey
    let hint: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.appHighlight, in: .circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.appInk)
                    Text(hint)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.appHighlight)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .cardSurface()
        }
        .buttonStyle(.pressableScale)
    }
}
