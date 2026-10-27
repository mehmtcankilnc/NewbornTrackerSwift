import Charts
import SwiftUI

/// Grouped bar chart: one column per day, one bar per record type.
struct RecordsChart: View {
    let points: [ChartPoint]
    let types: [RecordType]

    private var maxCount: Int { points.map(\.count).max() ?? 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Chart(points) { point in
                BarMark(
                    x: .value("Day", point.day, unit: .day),
                    y: .value("Records", point.count)
                )
                .foregroundStyle(by: .value("Type", name(of: point.type)))
                .position(by: .value("Type", name(of: point.type)))
                .cornerRadius(4)
            }
            .chartForegroundStyleScale(
                domain: types.map(name(of:)),
                range: types.map(\.accent)
            )
            .chartLegend(position: .top, alignment: .leading, spacing: 12)
            .chartYScale(domain: 0...max(maxCount, 1))
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    if let number = value.as(Double.self), number == number.rounded() {
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated), centered: true)
                }
            }
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: 7 * 24 * 3600)
            .chartScrollPosition(initialX: initialScrollDay)
            .frame(height: 260)

            if types.contains(.sleep) {
                Text("Sleep bars show session count, not duration.")
                    .scaledFont(size: 11)
                    .foregroundStyle(Color.appMuted)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    /// Start the visible week so the newest day sits at the right edge.
    private var initialScrollDay: Date {
        let newest = points.last?.day ?? .now
        return Calendar.current.date(byAdding: .day, value: -6, to: newest) ?? newest
    }

    private func name(of type: RecordType) -> String {
        String(localized: type.title)
    }
}
