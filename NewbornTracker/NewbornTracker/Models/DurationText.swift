import Foundation

enum DurationText {
    enum Style {
        /// "2 hr, 5 min"
        case regular
        /// "2h 5m"
        case compact
    }

    static func string(minutes: Int, style: Style = .regular, locale: Locale = .current) -> String {
        let width: Duration.UnitsFormatStyle.UnitWidth = style == .compact ? .narrow : .abbreviated

        return Duration.seconds(minutes * 60)
            .formatted(.units(allowed: [.hours, .minutes], width: width).locale(locale))
    }
}
