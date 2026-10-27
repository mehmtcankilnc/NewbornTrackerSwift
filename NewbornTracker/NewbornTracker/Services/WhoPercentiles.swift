import Foundation

/// The percentile lines we draw, with the Z-score of each (how many standard deviations from the median).
enum Percentile: CaseIterable {
    case p3, p15, p50, p85, p97

    var zScore: Double {
        switch self {
        case .p3: -1.8808
        case .p15: -1.0364
        case .p50: 0
        case .p85: 1.0364
        case .p97: 1.8808
        }
    }
}

enum WhoPercentiles {
    /// The WHO tables we ship stop at 24 months.
    static let maxMonths = 24.0

    /// The reference value for a metric at an age, or nil outside the 0–24 month table.
    static func value(for metric: GrowthMetric, gender: Gender, months: Double, percentile: Percentile) -> Double? {
        guard (0...maxMonths).contains(months),
              let points = WhoGrowthStandards.table[metric]?[gender],
              let lms = interpolate(points, at: months)
        else { return nil }

        return value(l: lms.l, m: lms.m, s: lms.s, z: percentile.zScore)
    }

    /// The standard WHO formula: the measurement value for a Z-score, given L, M and S.
    static func value(l: Double, m: Double, s: Double, z: Double) -> Double {
        if abs(l) < 1e-6 {
            return m * exp(s * z)
        }
        return m * pow(1 + l * s * z, 1 / l)
    }

    /// Linear interpolation of L, M and S between the two table rows around `months`.
    static func interpolate(_ points: [LmsPoint], at months: Double) -> LmsPoint? {
        guard let upper = points.firstIndex(where: { $0.months >= months }) else { return nil }
        guard upper > 0 else { return points[0] }

        let a = points[upper - 1]
        let b = points[upper]
        let ratio = (months - a.months) / (b.months - a.months)

        return LmsPoint(
            months: months,
            l: a.l + (b.l - a.l) * ratio,
            m: a.m + (b.m - a.m) * ratio,
            s: a.s + (b.s - a.s) * ratio
        )
    }
}
