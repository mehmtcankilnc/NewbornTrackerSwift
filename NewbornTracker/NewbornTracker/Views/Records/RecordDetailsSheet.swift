import SwiftUI

struct RecordDetailsSheet: View {
    let record: BabyRecord
    let onClose: () -> Void

    @State private var input: RecordEditInput

    init(record: BabyRecord, onClose: @escaping () -> Void) {
        self.record = record
        self.onClose = onClose
        _input = State(initialValue: RecordEditInput(record))
    }

    private var isDirty: Bool { input != RecordEditInput(record) }

    var body: some View {
        SheetScaffold(title: "Edit \(String(localized: record.type.title).lowercased()) record") {
            HStack(spacing: 12) {
                pickerCard("Date") {
                    DatePicker("", selection: $input.occurredAt, displayedComponents: .date)
                }
                pickerCard("Time") {
                    DatePicker("", selection: $input.occurredAt, displayedComponents: .hourAndMinute)
                }
            }

            switch record.type {
            case .feed:
                feedFields
            case .fever:
                PillTextField(title: "Temperature (°C)", placeholder: "e.g. 38.2", text: $input.health.temperatureText, keyboard: .decimalPad)
                    .onChange(of: input.health.temperatureText) { _, newValue in
                        input.health.temperatureText = String(newValue.prefix(5))
                    }
            case .medicine, .vitamin:
                PillTextField(
                    title: "Name / dose",
                    placeholder: record.type == .medicine ? "e.g. Paracetamol 5ml" : "e.g. Vitamin D",
                    text: $input.health.noteText
                )
                .onChange(of: input.health.noteText) { _, newValue in
                    input.health.noteText = String(newValue.prefix(60))
                }
            case .poop, .piss, .sleep:
                EmptyView()
            }

            VStack(spacing: 12) {
                PillButton(title: "Save") {
                    input.apply(to: record)
                    onClose()
                }
                .disabled(!isDirty || !input.detailsAreValid)

                PillButton(title: "Cancel", style: .secondary, action: onClose)
            }
        }
    }

    private var feedFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 8) {
                ForEach(FeedSubtype.allCases) { subtype in
                    OptionPill(title: String(localized: subtype.title), isSelected: input.feed.subtypes.contains(subtype)) {
                        input.feed.toggle(subtype)
                    }
                }
            }
            PillTextField(title: "Amount (ml, optional)", placeholder: "e.g. 120", text: $input.feed.amountText, keyboard: .numberPad)
                .onChange(of: input.feed.amountText) { _, newValue in
                    input.feed.amountText = String(newValue.prefix(4))
                }
        }
    }

    private func pickerCard<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .scaledFont(size: 12)
                .foregroundStyle(Color.appMuted)
            content()
                .labelsHidden()
                .tint(Color.appPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurfaceElevated, in: .rect(cornerRadius: 16))
    }
}
