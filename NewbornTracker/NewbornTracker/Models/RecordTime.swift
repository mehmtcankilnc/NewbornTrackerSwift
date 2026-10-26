import Foundation

enum RecordTime {
    /// Offsets for the "when did it happen?" chips; 0 means now.
    static let quickPickMinutes = [0, 3, 5, 10, 15, 30, 60]

    static func date(minutesAgo: Int, now: Date = .now) -> Date {
        now.addingTimeInterval(-TimeInterval(minutesAgo * 60))
    }

    /// Applies a picked time of day to today. A time later than now means yesterday.
    static func today(at time: Date, now: Date = .now, calendar: Calendar = .current) -> Date {
        let picked = calendar.dateComponents([.hour, .minute], from: time)

        guard let combined = calendar.date(
            bySettingHour: picked.hour ?? 0,
            minute: picked.minute ?? 0,
            second: 0,
            of: now
        ) else { return now }

        guard combined > now else { return combined }

        return calendar.date(byAdding: .day, value: -1, to: combined) ?? combined
    }
}
