import Foundation

/// What the user picked in a "when did it happen?" list.
enum TimeSelection: Equatable {
    case quick(minutesAgo: Int)
    case custom(Date)

    func resolved(now: Date = .now, calendar: Calendar = .current) -> Date {
        switch self {
        case .quick(let minutesAgo):
            RecordTime.date(minutesAgo: minutesAgo, now: now)
        case .custom(let time):
            RecordTime.today(at: time, now: now, calendar: calendar)
        }
    }
}
