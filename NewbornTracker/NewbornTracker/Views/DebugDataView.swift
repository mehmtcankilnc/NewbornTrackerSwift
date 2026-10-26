import SwiftData
import SwiftUI

/// Temporary screen to watch SwiftData work. Removed in Phase 3.
struct DebugDataView: View {
    @Environment(\.modelContext) private var context
    @Environment(ActiveBabyStore.self) private var activeBabyStore
    @Query(sort: \Baby.createdAt) private var babies: [Baby]

    private var activeBaby: Baby? { activeBabyStore.activeBaby(in: babies) }

    var body: some View {
        NavigationStack {
            List {
                Section("Babies") {
                    ForEach(babies) { baby in
                        Button {
                            activeBabyStore.select(baby)
                        } label: {
                            HStack {
                                Text(baby.name)
                                Spacer()
                                if baby.id == activeBaby?.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteBabies)

                    Button("Add baby") {
                        context.insert(Baby(name: "Baby \(babies.count + 1)"))
                    }
                }

                if let baby = activeBaby {
                    DebugRecordsSections(baby: baby)
                }
            }
            .navigationTitle("Debug data")
        }
    }

    private func deleteBabies(at offsets: IndexSet) {
        for index in offsets {
            context.delete(babies[index])
        }
    }
}

private struct DebugRecordsSections: View {
    let baby: Baby
    @Environment(\.modelContext) private var context
    @Query private var records: [BabyRecord]

    init(baby: Baby) {
        self.baby = baby
        let babyID = baby.id
        _records = Query(
            filter: #Predicate<BabyRecord> { $0.baby?.id == babyID },
            sort: \.occurredAt,
            order: .reverse
        )
    }

    var body: some View {
        let stats = TodayStats(records: records)

        Section("Add record for \(baby.name)") {
            ForEach(RecordType.allCases) { type in
                Button(String(localized: type.title)) {
                    let record = BabyRecord(type: type, occurredAt: .now)
                    context.insert(record)
                    record.baby = baby
                }
            }
        }

        Section("Today") {
            Text(RecordType.allCases.map { "\($0.rawValue) \(stats.count(for: $0))" }.joined(separator: " · "))
                .font(.footnote)
        }

        ForEach(DayGrouper.group(records)) { section in
            Section(title(for: section.day)) {
                ForEach(section.records) { record in
                    HStack {
                        Text(record.type.title)
                        Spacer()
                        Text(record.occurredAt, style: .time)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        context.delete(section.records[index])
                    }
                }
            }
        }
    }

    private func title(for day: Date) -> String {
        switch DayGrouper.heading(for: day) {
        case .today: "Today"
        case .yesterday: "Yesterday"
        case .date(let date): date.formatted(date: .abbreviated, time: .omitted)
        }
    }
}
