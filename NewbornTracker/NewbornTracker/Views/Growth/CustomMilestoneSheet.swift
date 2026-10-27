import SwiftData
import SwiftUI

/// Add a moment that is not on the built-in list, like a first laugh.
struct CustomMilestoneSheet: View {
    let baby: Baby
    let onClose: () -> Void

    @Environment(\.modelContext) private var context
    @State private var input = CustomItemInput()

    var body: some View {
        SheetScaffold(title: "New moment") {
            PillTextField(title: "Name", placeholder: "e.g. First laugh", text: $input.name)
                .onChange(of: input.name) { _, newValue in
                    input.name = String(newValue.prefix(60))
                }
            PillTextField(title: "Age range (optional)", placeholder: "e.g. Months 5-6", text: $input.ageText)
                .onChange(of: input.ageText) { _, newValue in
                    input.ageText = String(newValue.prefix(30))
                }

            VStack(spacing: 12) {
                PillButton(title: "Save") { save() }
                    .disabled(!input.canSave)
                PillButton(title: "Cancel", style: .secondary, action: onClose)
            }
        }
    }

    private func save() {
        if let milestone = input.makeMilestone() {
            context.insert(milestone)
            milestone.baby = baby
        }
        onClose()
    }
}
