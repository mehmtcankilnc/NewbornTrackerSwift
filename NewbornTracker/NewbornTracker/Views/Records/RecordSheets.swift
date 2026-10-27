import SwiftUI

struct RecordTypeFilterSheet: View {
    let selectedTypes: Set<RecordType>
    let onToggle: (RecordType) -> Void
    let onClear: () -> Void
    let onDone: () -> Void

    var body: some View {
        SheetScaffold(title: "Record type") {
            VStack(spacing: 8) {
                ForEach(RecordType.allCases) { type in
                    let isSelected = selectedTypes.contains(type)
                    Button {
                        onToggle(type)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: type.symbolName)
                                .scaledFont(size: 15)
                                .foregroundStyle(isSelected ? Color.white : type.accent)
                                .frame(width: 32, height: 32)
                                .background(isSelected ? Color.white.opacity(0.25) : type.accentBackground, in: .circle)
                            Text(String(localized: type.title))
                                .scaledFont(size: 16, weight: isSelected ? .semibold : .regular)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .scaledFont(size: 14, weight: .semibold)
                            }
                        }
                        .foregroundStyle(isSelected ? Color.white : Color.appInk)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(isSelected ? Color.appPrimary : Color.appSurfaceElevated, in: .capsule)
                    }
                    .buttonStyle(.pressableScale)
                }
            }

            VStack(spacing: 12) {
                PillButton(title: "Done", action: onDone)
                if !selectedTypes.isEmpty {
                    PillButton(title: "Clear", style: .secondary, action: onClear)
                }
            }
        }
    }
}

struct PeriodSheet: View {
    let period: Period
    let onSelect: (Period) -> Void
    let onCustom: () -> Void

    var body: some View {
        SheetScaffold(title: "Date range") {
            VStack(spacing: 8) {
                ForEach(Period.presets, id: \.self) { preset in
                    OptionPill(title: String(localized: preset.title), isSelected: period == preset) {
                        onSelect(preset)
                    }
                }
                OptionPill(title: String(localized: Period.custom(from: .now, to: .now).title), isSelected: isCustom, action: onCustom)
            }
        }
    }

    private var isCustom: Bool {
        if case .custom = period { return true }
        return false
    }
}

struct CustomRangeSheet: View {
    let onApply: (Date, Date) -> Void
    let onCancel: () -> Void

    @State private var start: Date
    @State private var end: Date

    init(start: Date, end: Date, onApply: @escaping (Date, Date) -> Void, onCancel: @escaping () -> Void) {
        _start = State(initialValue: start)
        _end = State(initialValue: end)
        self.onApply = onApply
        self.onCancel = onCancel
    }

    var body: some View {
        SheetScaffold(title: "Date range") {
            VStack(spacing: 8) {
                dateRow("Start", selection: $start)
                dateRow("End", selection: $end)
            }

            VStack(spacing: 12) {
                PillButton(title: "Apply") { onApply(start, end) }
                PillButton(title: "Cancel", style: .secondary, action: onCancel)
            }
        }
    }

    private func dateRow(_ title: LocalizedStringKey, selection: Binding<Date>) -> some View {
        HStack {
            Text(title)
                .scaledFont(size: 14)
                .foregroundStyle(Color.appMuted)
            Spacer()
            DatePicker("", selection: selection, displayedComponents: .date)
                .labelsHidden()
                .tint(Color.appPrimary)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 48)
        .background(Color.appSurfaceElevated, in: .capsule)
    }
}
