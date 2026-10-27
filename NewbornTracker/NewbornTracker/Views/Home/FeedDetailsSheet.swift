import SwiftUI

struct FeedDetailsSheet: View {
    let onConfirm: (FeedDetailsInput) -> Void
    let onCancel: () -> Void

    @State private var input = FeedDetailsInput()

    var body: some View {
        SheetScaffold(title: "Feed type") {
            VStack(spacing: 8) {
                ForEach(FeedSubtype.allCases) { subtype in
                    OptionPill(title: String(localized: subtype.title), isSelected: input.subtypes.contains(subtype)) {
                        input.toggle(subtype)
                    }
                }
            }

            PillTextField(
                title: "Amount (ml, optional)",
                placeholder: "e.g. 120",
                text: $input.amountText,
                keyboard: .numberPad
            )
            .onChange(of: input.amountText) { _, newValue in
                input.amountText = String(newValue.prefix(4))
            }

            VStack(spacing: 12) {
                PillButton(title: "Save") { onConfirm(input) }
                    .disabled(!input.canSave)
                PillButton(title: "Cancel", style: .secondary, action: onCancel)
            }
        }
    }
}
