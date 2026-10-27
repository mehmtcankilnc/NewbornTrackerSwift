import SwiftData
import SwiftUI

/// Add a vaccine that is not on the built-in schedule, or edit and delete one the parent added.
struct CustomVaccineSheet: View {
    let baby: Baby
    let vaccine: CustomVaccine?
    let onClose: () -> Void

    @Environment(\.modelContext) private var context
    @State private var input: CustomItemInput

    init(baby: Baby, vaccine: CustomVaccine?, onClose: @escaping () -> Void) {
        self.baby = baby
        self.vaccine = vaccine
        self.onClose = onClose
        _input = State(initialValue: vaccine.map { CustomItemInput(name: $0.name, ageLabel: $0.ageLabel) } ?? CustomItemInput())
    }

    var body: some View {
        SheetScaffold(title: vaccine == nil ? "Add vaccine" : "Edit vaccine") {
            PillTextField(title: "Vaccine name", placeholder: "e.g. Flu shot", text: $input.name)
                .onChange(of: input.name) { _, newValue in
                    input.name = String(newValue.prefix(60))
                }
            PillTextField(title: "Timing (optional)", placeholder: "e.g. Every autumn", text: $input.ageText)
                .onChange(of: input.ageText) { _, newValue in
                    input.ageText = String(newValue.prefix(30))
                }

            VStack(spacing: 12) {
                PillButton(title: "Save") { save() }
                    .disabled(!input.canSave)

                if let vaccine {
                    PillButton(title: "Delete", style: .destructive) {
                        context.delete(vaccine)
                        onClose()
                    }
                }

                PillButton(title: "Cancel", style: .secondary, action: onClose)
            }
        }
    }

    private func save() {
        if let vaccine {
            input.apply(to: vaccine)
        } else if let newVaccine = input.makeVaccine() {
            context.insert(newVaccine)
            newVaccine.baby = baby
        }
        onClose()
    }
}
