import Foundation

/// One of the baby's own measurements, placed on the age axis.
struct GrowthPoint: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let months: Double
    let value: Double
}

/// One point on a WHO percentile line.
struct PercentilePoint: Identifiable, Equatable {
    let percentile: Percentile
    let months: Double
    let value: Double

    var id: String { "\(percentile)-\(months)" }
}

enum GrowthSeries {
    /// The baby's values for one metric, oldest first. Measurements without that value are skipped.
    static func points(from measurements: [GrowthMeasurement], metric: GrowthMetric, birthDate: Date) -> [GrowthPoint] {
        measurements
            .compactMap { measurement in
                metric.value(in: measurement).map { value in
                    GrowthPoint(
                        id: measurement.id,
                        date: measurement.date,
                        months: GrowthAge.months(from: birthDate, to: measurement.date),
                        value: value
                    )
                }
            }
            .sorted { $0.months < $1.months }
    }

    /// The five WHO lines for the chart, one point per month from 0 to 24.
    static func percentileLines(metric: GrowthMetric, gender: Gender) -> [PercentilePoint] {
        Percentile.allCases.flatMap { percentile in
            stride(from: 0.0, through: WhoPercentiles.maxMonths, by: 1).compactMap { months in
                WhoPercentiles.value(for: metric, gender: gender, months: months, percentile: percentile)
                    .map { PercentilePoint(percentile: percentile, months: months, value: $0) }
            }
        }
    }
}
