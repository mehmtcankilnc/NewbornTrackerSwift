import SwiftUI

struct StopSleepSheet: View {
    let sleep: ActiveSleep
    let onStop: (Date) -> Void
    let onCancel: () -> Void

    @State private var selection: TimeSelection? = .quick(minutesAgo: 0)

    var body: some View {
        SheetScaffold(title: "Sleep timer") {
            VStack(spacing: 8) {
                Text("Sleeping since \(sleep.startedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appMuted)
                Text(timerInterval: sleep.startedAt...Date.distantFuture, countsDown: false, showsHours: true)
                    .font(.system(size: 44, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Color.appInk)
            }
            .frame(maxWidth: .infinity)

            Text("When did sleep end?")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.appInk)

            TimeSelectionList(selection: $selection)

            VStack(spacing: 12) {
                PillButton(title: "Stop sleep") {
                    if let selection {
                        onStop(selection.resolved())
                    }
                }
                .disabled(selection == nil)

                PillButton(title: "Cancel", style: .secondary, action: onCancel)
            }
        }
    }
}
