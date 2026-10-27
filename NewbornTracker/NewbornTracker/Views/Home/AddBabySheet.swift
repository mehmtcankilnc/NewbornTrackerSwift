import SwiftData
import SwiftUI

struct AddBabySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(ActiveBabyStore.self) private var activeBabyStore

    @State private var input = BabyInput()

    var body: some View {
        SheetScaffold(title: "Add your baby") {
            PillTextField(title: "Baby's name", placeholder: "Name", text: $input.name)

            VStack(alignment: .leading, spacing: 8) {
                Text("Gender (optional)")
                    .scaledFont(size: 12, weight: .semibold)
                    .foregroundStyle(Color.appMuted)
                ForEach(Gender.allCases) { gender in
                    OptionPill(title: String(localized: gender.title), isSelected: input.gender == gender) {
                        input.gender = input.gender == gender ? nil : gender
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Toggle("Add birth date", isOn: $input.hasBirthDate)
                    .scaledFont(size: 16)
                    .foregroundStyle(Color.appInk)
                    .tint(Color.appPrimary)
                if input.hasBirthDate {
                    DatePicker("Birth date", selection: $input.birthDate, in: ...Date.now, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .tint(Color.appPrimary)
                }
            }

            PillButton(title: "Save") { save() }
                .disabled(!input.canSave)
        }
    }

    private func save() {
        guard let baby = input.makeBaby() else { return }
        context.insert(baby)
        activeBabyStore.select(baby)
        dismiss()
    }
}
