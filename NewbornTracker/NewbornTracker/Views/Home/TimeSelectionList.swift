import SwiftUI

/// "Now", a few "minutes ago" options and a custom time. Shared by the time picker and stop-sleep sheets.
struct TimeSelectionList: View {
    @Binding var selection: TimeSelection?

    @State private var customTime = Date.now
    @State private var isPickingCustom = false

    var body: some View {
        VStack(spacing: 8) {
            ForEach(RecordTime.quickPickMinutes, id: \.self) { minutes in
                OptionPill(
                    title: minutes == 0 ? String(localized: "Now") : String(localized: "\(minutes) min ago"),
                    isSelected: selection == .quick(minutesAgo: minutes)
                ) {
                    selection = .quick(minutesAgo: minutes)
                    isPickingCustom = false
                }
            }

            OptionPill(title: customTitle, isSelected: isCustomSelected) {
                isPickingCustom.toggle()
                if isPickingCustom {
                    selection = .custom(customTime)
                }
            }

            if isPickingCustom {
                DatePicker("Time", selection: $customTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .onChange(of: customTime) { _, newValue in
                        selection = .custom(newValue)
                    }
            }
        }
    }

    private var isCustomSelected: Bool {
        if case .custom = selection { return true }
        return false
    }

    private var customTitle: String {
        if case .custom(let time) = selection {
            return String(localized: "Custom: \(time.formatted(date: .omitted, time: .shortened))")
        }
        return String(localized: "Custom…")
    }
}
