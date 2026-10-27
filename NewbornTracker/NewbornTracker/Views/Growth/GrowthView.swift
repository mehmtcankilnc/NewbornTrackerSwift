import SwiftData
import SwiftUI

struct GrowthView: View {
    @Query(sort: \Baby.createdAt) private var babies: [Baby]
    @Environment(ActiveBabyStore.self) private var activeBabyStore

    var body: some View {
        Group {
            if let baby = activeBabyStore.activeBaby(in: babies) {
                GrowthContent(baby: baby)
            } else {
                ContentUnavailableView("No baby yet", systemImage: "heart", description: Text("Add your baby on the Home tab."))
                    .foregroundStyle(Color.appInk)
            }
        }
        .background(Color.appSurface.ignoresSafeArea())
    }
}

private enum GrowthSection: CaseIterable {
    case vaccines, growth, milestones

    var title: LocalizedStringKey {
        switch self {
        case .vaccines: "Vaccines"
        case .growth: "Growth"
        case .milestones: "Milestones"
        }
    }
}

private enum GrowthSheet: Identifiable {
    case new
    case edit(GrowthMeasurement)

    var id: String {
        switch self {
        case .new: "new"
        case .edit(let measurement): "edit-\(measurement.id)"
        }
    }

    var measurement: GrowthMeasurement? {
        if case .edit(let measurement) = self { return measurement }
        return nil
    }
}

private struct GrowthContent: View {
    let baby: Baby

    @Query private var measurements: [GrowthMeasurement]
    @State private var section = GrowthSection.vaccines
    @State private var metric = GrowthMetric.weight
    @State private var sheet: GrowthSheet?
    @State private var isShowingInfo = false

    init(baby: Baby) {
        self.baby = baby
        let babyID = baby.id
        _measurements = Query(
            filter: #Predicate<GrowthMeasurement> { $0.baby?.id == babyID },
            sort: \.date,
            order: .reverse
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Growth")
                        .scaledFont(size: 24, weight: .heavy)
                        .foregroundStyle(Color.appInk)
                    Spacer()
                    SettingsButton()
                }

                Picker("Section", selection: $section) {
                    ForEach(GrowthSection.allCases, id: \.self) { section in
                        Text(section.title).tag(section)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            ScrollView {
                switch section {
                case .growth:
                    growthSection
                case .vaccines:
                    VaccineSection(baby: baby)
                case .milestones:
                    MilestoneSection(baby: baby)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(item: $sheet) { sheet in
            GrowthEntrySheet(baby: baby, measurement: sheet.measurement) {
                self.sheet = nil
            }
        }
        .alert("WHO percentile curves", isPresented: $isShowingInfo) {
            Button("OK") {}
        } message: {
            Text("These curves come from the World Health Organization's growth data, collected from millions of children of the same age and sex. The P50 line is the median, and the others (P3–P97) mark the lower and upper bounds of the typical range. If your baby's own line tracks steadily within these bands, growth is following its own curve. What matters is the trend over time, not a single measurement. Talk to your pediatrician if you have concerns.")
        }
    }

    @ViewBuilder
    private var growthSection: some View {
        if let birthDate = baby.birthDate, let gender = baby.gender {
            growthBody(birthDate: birthDate, gender: gender)
        } else {
            birthInfoCard
        }
    }

    private func growthBody(birthDate: Date, gender: Gender) -> some View {
        let points = GrowthSeries.points(from: measurements, metric: metric, birthDate: birthDate)

        return VStack(alignment: .leading, spacing: 12) {
            Picker("Measurement", selection: $metric) {
                ForEach(GrowthMetric.allCases) { metric in
                    Text(metric.shortTitle).tag(metric)
                }
            }
            .pickerStyle(.segmented)

            GrowthChart(
                metric: metric,
                lines: GrowthSeries.percentileLines(metric: metric, gender: gender),
                points: points
            )

            HStack(spacing: 6) {
                Text("WHO percentile curves (P3–P97)")
                Button {
                    isShowingInfo = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("About percentile curves")
            }
            .scaledFont(size: 11)
            .foregroundStyle(Color.appMuted)
            .frame(maxWidth: .infinity)

            AddEntryCard(
                symbol: "chart.xyaxis.line",
                title: "Add measurement",
                hint: "Weight, height and head circumference"
            ) {
                sheet = .new
            }

            history(points: points)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }

    @ViewBuilder
    private func history(points: [GrowthPoint]) -> some View {
        if points.isEmpty {
            Text("No measurements yet.")
                .scaledFont(size: 14)
                .foregroundStyle(Color.appMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        } else {
            VStack(spacing: 8) {
                ForEach(points.reversed()) { point in
                    if let measurement = measurements.first(where: { $0.id == point.id }) {
                        Button {
                            sheet = .edit(measurement)
                        } label: {
                            historyRow(point)
                        }
                        .buttonStyle(.pressableScale)
                    }
                }
            }
        }
    }

    private func historyRow(_ point: GrowthPoint) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(point.date.formatted(.dateTime.day().month(.wide).year()))
                    .scaledFont(size: 14, weight: .semibold)
                    .foregroundStyle(Color.appInk)
                Text("Month \(Int(point.months.rounded()))")
                    .scaledFont(size: 12)
                    .foregroundStyle(Color.appMuted)
            }
            Spacer()
            Text(metric.formatted(point.value))
                .scaledFont(size: 14, weight: .bold)
                .foregroundStyle(Color.appInk)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .cardSurface(cornerRadius: 16, shadowRadius: 3, shadowY: 1)
    }

    private var birthInfoCard: some View {
        VStack(spacing: 6) {
            Image(systemName: "calendar")
                .scaledFont(size: 22)
                .foregroundStyle(Color.appMuted)
                .padding(.bottom, 6)
            Text("Birth date and gender needed")
                .scaledFont(size: 14, weight: .semibold)
                .foregroundStyle(Color.appInk)
            Text("Add a birth date and gender to compare against percentile curves.")
                .scaledFont(size: 12)
                .foregroundStyle(Color.appMuted)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.appSurfaceElevated, in: .rect(cornerRadius: 20))
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}
