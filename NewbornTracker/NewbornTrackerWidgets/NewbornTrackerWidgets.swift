import AppIntents
import SwiftData
import SwiftUI
import WidgetKit

struct HomeEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct HomeProvider: TimelineProvider {
    func placeholder(in context: Context) -> HomeEntry {
        HomeEntry(date: .now, snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (HomeEntry) -> Void) {
        if context.isPreview {
            completion(HomeEntry(date: .now, snapshot: .preview))
            return
        }
        Task { completion(HomeEntry(date: .now, snapshot: await loadSnapshot())) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HomeEntry>) -> Void) {
        Task {
            let entry = HomeEntry(date: .now, snapshot: await loadSnapshot())
            // Counts start over at midnight. Everything else reloads when the app or a button changes the data.
            let midnight = Calendar.current.startOfDay(for: .now).addingTimeInterval(24 * 3600)
            completion(Timeline(entries: [entry], policy: .after(midnight)))
        }
    }

    private func loadSnapshot() async -> WidgetSnapshot {
        let activeID = UserDefaults(suiteName: AppSchema.appGroupID)?
            .string(forKey: AppSchema.activeBabyDefaultsKey)
            .flatMap(UUID.init(uuidString:))

        do {
            let container = try await MainActor.run { try AppSchema.makeContainer() }
            return try await WidgetDataService(modelContainer: container).snapshot(activeBabyID: activeID)
        } catch {
            return .empty
        }
    }
}

private extension WidgetSnapshot {
    static let preview = WidgetSnapshot(
        babyID: UUID(),
        babyName: "Mia",
        records: [
            RecordValue(type: .poop, occurredAt: .now),
            RecordValue(type: .feed, occurredAt: .now),
            RecordValue(type: .feed, occurredAt: .now),
            RecordValue(type: .sleep, occurredAt: .now, durationMinutes: 95),
        ],
        sleepStartedAt: nil
    )
}

struct HomeWidgetView: View {
    let entry: HomeEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let babyID = entry.snapshot.babyID, let name = entry.snapshot.babyName {
            content(babyID: babyID, name: name)
        } else {
            Text("Add your baby to start logging.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.appMuted)
                .multilineTextAlignment(.center)
        }
    }

    private func content(babyID: UUID, name: String) -> some View {
        let snapshot = entry.snapshot
        let columns = family == .systemSmall ? 2 : 4

        return VStack(alignment: .leading, spacing: 10) {
            Text("Hi, \(name)! 👶")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(Color.appInk)
                .lineLimit(1)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns), spacing: 8) {
                ForEach([RecordType.poop, .piss, .feed], id: \.self) { type in
                    Button(intent: AddRecordIntent(type: type, babyID: babyID)) {
                        tile(symbol: type.symbolName, accent: type.accent, background: type.accentBackground) {
                            Text("\(snapshot.count(for: type))")
                        }
                    }
                    .buttonStyle(.plain)
                }
                sleepTile(snapshot)
            }
        }
    }

    private func sleepTile(_ snapshot: WidgetSnapshot) -> some View {
        tile(symbol: RecordType.sleep.symbolName, accent: RecordType.sleep.accent, background: RecordType.sleep.accentBackground) {
            if let start = snapshot.sleepStartedAt {
                Text(timerInterval: start...Date.distantFuture, countsDown: false)
                    .monospacedDigit()
            } else {
                Text(snapshot.sleepMinutesToday > 0
                     ? DurationText.string(minutes: snapshot.sleepMinutesToday, style: .compact)
                     : "—")
            }
        }
    }

    private func tile<Value: View>(symbol: String, accent: Color, background: Color, @ViewBuilder value: () -> Value) -> some View {
        VStack(spacing: 2) {
            Image(systemName: symbol)
                .font(.system(size: 14))
                .foregroundStyle(accent)
            value()
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.appInk)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(background, in: .rect(cornerRadius: 14))
    }
}

struct HomeWidget: Widget {
    let kind = "HomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HomeProvider()) { entry in
            HomeWidgetView(entry: entry)
                .containerBackground(Color.appSurface, for: .widget)
        }
        .configurationDisplayName("Today at a glance")
        .description("Today's counts. Tap poop, pee or feed to log one.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    HomeWidget()
} timeline: {
    HomeEntry(date: .now, snapshot: .preview)
}

#Preview(as: .systemMedium) {
    HomeWidget()
} timeline: {
    HomeEntry(date: .now, snapshot: .preview)
}
