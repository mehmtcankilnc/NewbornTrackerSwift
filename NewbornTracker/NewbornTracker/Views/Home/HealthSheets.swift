import SwiftUI

struct HealthTypePickerSheet: View {
    let onSelect: (RecordType) -> Void

    var body: some View {
        SheetScaffold(title: "What do you want to log?") {
            VStack(spacing: 8) {
                ForEach(RecordType.health) { type in
                    Button {
                        onSelect(type)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: type.symbolName)
                                .scaledFont(size: 16)
                                .foregroundStyle(type.accent)
                                .frame(width: 36, height: 36)
                                .background(type.accentBackground, in: .circle)
                            Text(String(localized: type.title))
                                .scaledFont(size: 16, weight: .semibold)
                                .foregroundStyle(Color.appInk)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(Color.appSurfaceElevated, in: .capsule)
                    }
                    .buttonStyle(.pressableScale)
                }
            }
        }
    }
}

struct HealthDetailsSheet: View {
    let onConfirm: (HealthDetailsInput) -> Void
    let onCancel: () -> Void

    @State private var input: HealthDetailsInput
    @FocusState private var isFocused: Bool

    init(type: RecordType, onConfirm: @escaping (HealthDetailsInput) -> Void, onCancel: @escaping () -> Void) {
        _input = State(initialValue: HealthDetailsInput(type: type))
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    var body: some View {
        SheetScaffold(title: input.type.title) {
            if input.type == .fever {
                PillTextField(
                    title: "Temperature (°C)",
                    placeholder: "e.g. 38.2",
                    text: $input.temperatureText,
                    keyboard: .decimalPad
                )
                .focused($isFocused)
                .onChange(of: input.temperatureText) { _, newValue in
                    input.temperatureText = String(newValue.prefix(5))
                }
            } else {
                PillTextField(
                    title: "Name / dose",
                    placeholder: input.type == .medicine ? "e.g. Paracetamol 5ml" : "e.g. Vitamin D",
                    text: $input.noteText
                )
                .focused($isFocused)
                .onChange(of: input.noteText) { _, newValue in
                    input.noteText = String(newValue.prefix(60))
                }
            }

            VStack(spacing: 12) {
                PillButton(title: "Save") { onConfirm(input) }
                    .disabled(!input.canSave)
                PillButton(title: "Cancel", style: .secondary, action: onCancel)
            }
        }
        .onAppear { isFocused = true }
    }
}
