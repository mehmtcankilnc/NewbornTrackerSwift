import Foundation

/// Everything the Home cards show: today's counts plus the time of the latest record per type.
struct HomeSummary: Equatable {
    let stats: TodayStats
    private let lastTimes: [RecordType: Date]

    init<Record: LoggedRecord>(records: [Record], now: Date = .now, calendar: Calendar = .current) {
        stats = TodayStats(records: records, now: now, calendar: calendar)

        let latestByType = Dictionary(grouping: records, by: \.type)
            .compactMapValues { $0.max { $0.occurredAt < $1.occurredAt } }
        lastTimes = latestByType.compactMapValues { $0.type == .sleep ? $0.endedAt : $0.occurredAt }
    }

    var sleepMinutes: Int { stats.sleepMinutes }

    func count(for type: RecordType) -> Int { stats.count(for: type) }

    /// When the latest record of this type happened. For sleep that is when it ended.
    func lastTime(for type: RecordType) -> Date? { lastTimes[type] }

    var healthCountToday: Int {
        RecordType.health.reduce(0) { $0 + stats.count(for: $1) }
    }

    var lastHealthTime: Date? {
        RecordType.health.compactMap { lastTimes[$0] }.max()
    }
}
