import SwiftUI

/// Edits the active baby's name, birth date and gender. Changes are saved as you type.
struct ProfileSection: View {
    let baby: Baby
    @State private var input: BabyInput

    init(baby: Baby) {
        self.baby = baby
        _input = State(initialValue: BabyInput(baby))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SettingsSection(title: "Baby's name") {
                TextField("Name", text: $input.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.appInk)
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(Color.appSurfaceElevated, in: .capsule)
                    .onChange(of: input.name) { _, newValue in
                        input.name = String(newValue.prefix(30))
                    }
            }

            SettingsSection(title: "Birth date") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Add birth date", isOn: $input.hasBirthDate)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.appInk)
                        .tint(Color.appPrimary)
                    if input.hasBirthDate {
                        DatePicker("Birth date", selection: $input.birthDate, in: ...Date.now, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .tint(Color.appPrimary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.appSurfaceElevated, in: .rect(cornerRadius: 16))
            }

            SettingsSection(title: "Gender") {
                VStack(spacing: 8) {
                    ForEach(Gender.allCases) { gender in
                        OptionPill(title: String(localized: gender.title), isSelected: input.gender == gender) {
                            input.gender = input.gender == gender ? nil : gender
                        }
                    }
                }
            }
        }
        .onChange(of: input) { _, newValue in
            newValue.apply(to: baby)
        }
    }
}
