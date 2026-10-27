import Charts
import SwiftUI

/// The five WHO percentile lines with the baby's own measurements drawn on top.
struct GrowthChart: View {
    let metric: GrowthMetric
    let lines: [PercentilePoint]
    let points: [GrowthPoint]

    /// The WHO lines stop at 24 months. If the baby is older, the axis grows with the measurements.
    private var maxMonths: Double {
        max(WhoPercentiles.maxMonths, (points.last?.months ?? 0).rounded(.up))
    }

    var body: some View {
        Chart {
            ForEach(lines) { line in
                let isMedian = line.percentile == .p50
                LineMark(
                    x: .value("Age (months)", line.months),
                    y: .value("Value", line.value),
                    series: .value("Line", "\(line.percentile)")
                )
                .foregroundStyle(isMedian ? Color.appMuted : Color.appBorder)
                .lineStyle(StrokeStyle(lineWidth: isMedian ? 1.5 : 1, dash: isMedian ? [] : [3, 3]))
            }

            ForEach(points) { point in
                LineMark(
                    x: .value("Age (months)", point.months),
                    y: .value("Value", point.value),
                    series: .value("Line", "baby")
                )
                .foregroundStyle(Color.appPrimary)
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                PointMark(
                    x: .value("Age (months)", point.months),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(Color.appPrimary)
                .symbolSize(45)
            }
        }
        .chartXScale(domain: 0...maxMonths)
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis {
            AxisMarks(values: .stride(by: 6)) { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartYAxisLabel(metric.unitSymbol, position: .top, alignment: .leading)
        .frame(height: 240)
    }
}
