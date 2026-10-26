import Foundation

enum Period: Equatable {
    case all
    case today
    case week
    case month
    case custom(from: Date, to: Date)

    /// The periods offered as one-tap options. Custom needs a date range from the user.
    static let presets: [Period] = [.all, .today, .week, .month]

    func contains(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        switch self {
        case .all:
            return true
        case .today:
            return calendar.isDate(date, inSameDayAs: now)
        case .week:
            guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return false }
            return date >= week.start && date < week.end
        case .month:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        case .custom(let from, let to):
            let start = calendar.startOfDay(for: min(from, to))
            let lastDay = calendar.startOfDay(for: max(from, to))
            guard let end = calendar.date(byAdding: .day, value: 1, to: lastDay) else { return false }
            return date >= start && date < end
        }
    }
}
