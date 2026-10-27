import SwiftUI

struct TimePickerSheet: View {
    let title: LocalizedStringResource
    let onSelect: (Date) -> Void
    let onCancel: () -> Void

    @State private var selection: TimeSelection?

    var body: some View {
        SheetScaffold(title: title) {
            TimeSelectionList(selection: $selection)

            VStack(spacing: 12) {
                PillButton(title: "Confirm") {
                    if let selection {
                        onSelect(selection.resolved())
                    }
                }
                .disabled(selection == nil)

                PillButton(title: "Cancel", style: .secondary, action: onCancel)
            }
        }
    }
}
