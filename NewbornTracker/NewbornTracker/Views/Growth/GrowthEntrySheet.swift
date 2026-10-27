import SwiftData
import SwiftUI

/// Add a measurement, or edit and delete a saved one.
struct GrowthEntrySheet: View {
    let baby: Baby
    let measurement: GrowthMeasurement?
    let onClose: () -> Void

    @Environment(\.modelContext) private var context
    @State private var input: GrowthEntryInput

    init(baby: Baby, measurement: GrowthMeasurement?, onClose: @escaping () -> Void) {
        self.baby = baby
        self.measurement = measurement
        self.onClose = onClose
        _input = State(initialValue: measurement.map { GrowthEntryInput($0) } ?? GrowthEntryInput())
    }

    var body: some View {
        SheetScaffold(title: measurement == nil ? "Add measurement" : "Edit measurement") {
            HStack {
                Text("Date")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appMuted)
                Spacer()
                DatePicker("", selection: $input.date, in: ...Date.now, displayedComponents: .date)
                    .labelsHidden()
                    .tint(Color.appPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.appSurfaceElevated, in: .rect(cornerRadius: 16))

            PillTextField(title: "Weight (kg)", placeholder: "—", text: $input.weightText, keyboard: .decimalPad)
                .onChange(of: input.weightText) { _, newValue in
                    input.weightText = String(newValue.prefix(6))
                }
            PillTextField(title: "Height (cm)", placeholder: "—", text: $input.heightText, keyboard: .decimalPad)
                .onChange(of: input.heightText) { _, newValue in
                    input.heightText = String(newValue.prefix(6))
                }
            PillTextField(title: "Head circumference (cm)", placeholder: "—", text: $input.headText, keyboard: .decimalPad)
                .onChange(of: input.headText) { _, newValue in
                    input.headText = String(newValue.prefix(6))
                }

            VStack(spacing: 12) {
                PillButton(title: "Save") { save() }
                    .disabled(!input.canSave)

                if let measurement {
                    PillButton(title: "Delete", style: .destructive) {
                        context.delete(measurement)
                        onClose()
                    }
                }

                PillButton(title: "Cancel", style: .secondary, action: onClose)
            }
        }
    }

    private func save() {
        if let measurement {
            input.apply(to: measurement)
        } else if let newMeasurement = input.makeMeasurement() {
            context.insert(newMeasurement)
            newMeasurement.baby = baby
        }
        onClose()
    }
}
