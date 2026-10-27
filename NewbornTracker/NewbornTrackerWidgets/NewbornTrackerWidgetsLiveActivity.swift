import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// The sleep timer on the lock screen and in the Dynamic Island.
struct SleepLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SleepActivityAttributes.self) { context in
            lockScreen(context.attributes)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.babyName, systemImage: "moon.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(RecordType.sleep.accent)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    timer(since: context.attributes.startedAt)
                        .font(.system(size: 22, weight: .bold).monospacedDigit())
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 90, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    stopButton(babyID: context.attributes.babyID)
                }
            } compactLeading: {
                Image(systemName: "moon.fill")
                    .foregroundStyle(RecordType.sleep.accent)
            } compactTrailing: {
                timer(since: context.attributes.startedAt)
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 52)
            } minimal: {
                Image(systemName: "moon.fill")
                    .foregroundStyle(RecordType.sleep.accent)
            }
        }
    }

    private func lockScreen(_ attributes: SleepActivityAttributes) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "moon.fill")
                .font(.system(size: 20))
                .foregroundStyle(RecordType.sleep.accent)
                .frame(width: 44, height: 44)
                .background(RecordType.sleep.accentBackground, in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(attributes.babyName) is sleeping")
                    .font(.system(size: 15, weight: .semibold))
                timer(since: attributes.startedAt)
                    .font(.system(size: 26, weight: .bold).monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer(minLength: 0)
            stopButton(babyID: attributes.babyID)
                .frame(width: 110)
        }
        .padding(16)
        .activityBackgroundTint(Color.appSurfaceElevated)
        .activitySystemActionForegroundColor(Color.appInk)
    }

    /// A running clock that ticks by itself. The system draws it, so the activity needs no updates.
    private func timer(since start: Date) -> some View {
        Text(timerInterval: start...Date.distantFuture, countsDown: false)
    }

    private func stopButton(babyID: UUID) -> some View {
        Button(intent: StopSleepIntent(babyID: babyID)) {
            Text("Stop sleep")
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
        }
        .tint(Color.appPrimary)
    }
}
