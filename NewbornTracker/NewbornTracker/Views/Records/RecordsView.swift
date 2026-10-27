import SwiftData
import SwiftUI

struct RecordsView: View {
    let onGoHome: () -> Void
    
    @Query(sort: \Baby.createdAt) private var babies: [Baby]
    @Environment(ActiveBabyStore.self) private var activeBabyStore
    
    var body: some View {
        Group {
            if let baby = activeBabyStore.activeBaby(in: babies) {
                RecordsContent(baby: baby, onGoHome: onGoHome)
            } else {
                ContentUnavailableView("No baby yet", systemImage: "heart", description: Text("Add your baby on the Home tab."))
                    .foregroundStyle(Color.appInk)
            }
        }
        .background(Color.appSurface.ignoresSafeArea())
    }
}

private enum RecordsDisplay {
    case list
    case chart
}

private enum RecordsSheet: Identifiable {
    case types
    case period
    case customRange
    case edit(BabyRecord)
    
    var id: String {
        switch self {
        case .types: "types"
        case .period: "period"
        case .customRange: "customRange"
        case .edit(let record): "edit-\(record.id)"
        }
    }
}

private struct RecordsContent: View {
    let baby: Baby
    let onGoHome: () -> Void
    
    @Environment(\.modelContext) private var context
    @Query private var records: [BabyRecord]
    @State private var filter = RecordFilter()
    @State private var sheet: RecordsSheet?
    @State private var recordToDelete: BabyRecord?
    @State private var display: RecordsDisplay = .list
    
    init(baby: Baby, onGoHome: @escaping () -> Void) {
        self.baby = baby
        self.onGoHome = onGoHome
        let babyID = baby.id
        _records = Query(filter: #Predicate<BabyRecord> { $0.baby?.id == babyID })
    }
    
    var body: some View {
        let filtered = filter.apply(to: records)
        let emptyState = RecordsEmptyState(totalCount: records.count, filteredCount: filtered.count)
        
        VStack(alignment: .leading, spacing: 0) {
            filterBar
                .padding(.horizontal, 20)
                .padding(.top, 16)
            
            if let emptyState {
                emptyView(emptyState)
            } else if display == .chart {
                RecordsChart(
                    points: ChartData.points(from: filtered, types: ChartData.types(for: filter)),
                    types: ChartData.types(for: filter)
                )
                Spacer(minLength: 0)
            } else {
                recordList(DayGrouper.group(filtered))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(item: $sheet) { sheet in
            sheetContent(for: sheet)
        }
        .alert(
            "Delete this record?",
            isPresented: Binding(get: { recordToDelete != nil }, set: { if !$0 { recordToDelete = nil } }),
            presenting: recordToDelete
        ) { record in
            Button("Delete", role: .destructive) {
                context.delete(record)
            }
            Button("Cancel", role: .cancel) {}
        } message: { record in
            Text("This \(String(localized: record.type.title).lowercased()) record will be deleted.")
        }
    }
    
    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Records")
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(Color.appInk)
            
            HStack(spacing: 8) {
                FilterTrigger(symbol: "line.3.horizontal.decrease", title: typeFilterTitle, isActive: !filter.types.isEmpty) {
                    sheet = .types
                }
                FilterTrigger(symbol: "calendar", title: periodTitle) {
                    sheet = .period
                }
                Spacer(minLength: 0)
                Picker("View", selection: $display) {
                    Image(systemName: "list.bullet").tag(RecordsDisplay.list)
                    Image(systemName: "chart.bar.fill").tag(RecordsDisplay.chart)
                }
                .pickerStyle(.segmented)
                .frame(width: 96)
            }
            
            if !filter.types.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(RecordType.allCases.filter(filter.types.contains)) { type in
                            RemovableChip(title: String(localized: type.title)) {
                                filter.toggleType(type)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var typeFilterTitle: String {
        let selected = RecordType.allCases.filter(filter.types.contains)
        switch selected.count {
        case 0: return String(localized: "All")
        case 1: return String(localized: selected[0].title)
        default: return String(localized: "\(selected.count) types selected")
        }
    }
    
    private var periodTitle: String {
        if case .custom(let from, let to) = filter.period {
            let format = Date.FormatStyle().day().month(.abbreviated)
            return "\(min(from, to).formatted(format)) – \(max(from, to).formatted(format))"
        }
        return String(localized: filter.period.title)
    }
    
    private func recordList(_ sections: [DaySection<BabyRecord>]) -> some View {
        List {
            ForEach(sections) { section in
                Section {
                    ForEach(section.records) { record in
                        Button {
                            sheet = .edit(record)
                        } label: {
                            RecordRow(record: record)
                        }
                        .buttonStyle(.pressableScale)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                recordToDelete = record
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(Color.appDanger)
                        }
                        .contextMenu {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                recordToDelete = record
                            }
                        }
                    }
                } header: {
                    dayHeader(for: section)
                }
                .listSectionSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    private func dayHeader(for section: DaySection<BabyRecord>) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(headingText(for: section.day))
                .textCase(.uppercase)
            Spacer()
            if let summary = summaryText(DaySummary(records: section.records, filter: filter)) {
                Text(summary)
            }
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(Color.appMuted)
        .padding(.horizontal, 4)
        .padding(.top, 8)
        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
    }
    
    private func headingText(for day: Date) -> String {
        switch DayGrouper.heading(for: day) {
        case .today: String(localized: "Today")
        case .yesterday: String(localized: "Yesterday")
        case .date(let date): date.formatted(.dateTime.day().month(.wide).weekday(.wide))
        }
    }
    
    private func summaryText(_ summary: DaySummary) -> String? {
        switch summary {
        case .none:
            return nil
        case .count(let count):
            return String(localized: "\(count) records")
        case .feedBreakdown(let breakdown):
            var parts = breakdown.entries.map { "\($0.count) \(String(localized: $0.subtype.title).lowercased())" }
            if breakdown.untyped > 0 {
                parts.append("\(breakdown.untyped) " + String(localized: "other"))
            }
            return parts.joined(separator: " · ")
        }
    }
    
    private func emptyView(_ state: RecordsEmptyState) -> some View {
        VStack(spacing: 6) {
            Text(state == .noRecords ? "No records yet" : "No records match these filters")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.appInk)
                .multilineTextAlignment(.center)
            Text(state == .noRecords
                 ? "It'll show up here once you log a poop, pee, feed, or sleep from Home."
                 : "Try a different filter or clear them.")
            .font(.system(size: 14))
            .foregroundStyle(Color.appMuted)
            .multilineTextAlignment(.center)
            if state == .noRecords {
                PillButton(title: "Go to Home", action: onGoHome)
                    .padding(.horizontal, 60)
                    .padding(.top, 18)
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 64)
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func sheetContent(for sheet: RecordsSheet) -> some View {
        switch sheet {
        case .types:
            RecordTypeFilterSheet(
                selectedTypes: filter.types,
                onToggle: { filter.toggleType($0) },
                onClear: { filter.types.removeAll() },
                onDone: { self.sheet = nil }
            )
        case .period:
            PeriodSheet(
                period: filter.period,
                onSelect: { period in
                    filter.period = period
                    self.sheet = nil
                },
                onCustom: { self.sheet = .customRange }
            )
        case .customRange:
            CustomRangeSheet(start: customStart, end: customEnd) { start, end in
                filter.period = .custom(from: start, to: end)
                self.sheet = nil
            } onCancel: {
                self.sheet = nil
            }
        case .edit(let record):
            RecordDetailsSheet(record: record) {
                self.sheet = nil
            }
        }
    }
    
    private var customStart: Date {
        if case .custom(let from, _) = filter.period { return from }
        return .now
    }
    
    private var customEnd: Date {
        if case .custom(_, let to) = filter.period { return to }
        return .now
    }
}
