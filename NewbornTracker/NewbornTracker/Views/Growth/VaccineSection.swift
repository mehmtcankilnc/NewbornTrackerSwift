import SwiftData
import SwiftUI

private enum VaccineSheet: Identifiable {
    case new
    case edit(CustomVaccine)

    var id: String {
        switch self {
        case .new: "new"
        case .edit(let vaccine): "edit-\(vaccine.id)"
        }
    }

    var vaccine: CustomVaccine? {
        if case .edit(let vaccine) = self { return vaccine }
        return nil
    }
}

/// The vaccine checklist: the built-in schedule plus the vaccines the parent added.
struct VaccineSection: View {
    let baby: Baby

    @Environment(\.modelContext) private var context
    @Query private var completions: [VaccineCompletion]
    @Query private var customVaccines: [CustomVaccine]
    @State private var sheet: VaccineSheet?
    @State private var vaccineToDelete: CustomVaccine?

    init(baby: Baby) {
        self.baby = baby
        let babyID = baby.id
        _completions = Query(filter: #Predicate<VaccineCompletion> { $0.baby?.id == babyID })
        _customVaccines = Query(filter: #Predicate<CustomVaccine> { $0.baby?.id == babyID })
    }

    var body: some View {
        let rows = VaccineChecklist.rows(
            completedIDs: Set(completions.map(\.scheduleID)),
            customVaccines: customVaccines
        )
        let progress = VaccineChecklist.progress(of: rows)

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Vaccine schedule")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.appInk)
                Spacer()
                Text("\(progress.done)/\(progress.total)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.appMuted)
            }

            Text("A general guide. Check with your pediatrician for the exact schedule.")
                .font(.system(size: 12))
                .foregroundStyle(Color.appMuted)

            AddEntryCard(
                symbol: "cross.case.fill",
                title: "Add vaccine",
                hint: "Add a vaccine that isn't on the built-in schedule."
            ) {
                sheet = .new
            }

            VStack(spacing: 8) {
                ForEach(rows) { row in
                    ChecklistRow(title: row.name, subtitle: row.ageLabel, isDone: row.isDone) {
                        context.toggleVaccine(row.source, for: baby)
                    } leading: {
                        CheckCircle(isDone: row.isDone)
                    }
                    .contextMenu {
                        if case .custom(let id) = row.source,
                           let vaccine = customVaccines.first(where: { $0.id == id }) {
                            Button("Edit", systemImage: "pencil") { sheet = .edit(vaccine) }
                            Button("Delete", systemImage: "trash", role: .destructive) { vaccineToDelete = vaccine }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .sheet(item: $sheet) { sheet in
            CustomVaccineSheet(baby: baby, vaccine: sheet.vaccine) {
                self.sheet = nil
            }
        }
        .alert(
            "Delete this vaccine?",
            isPresented: Binding(get: { vaccineToDelete != nil }, set: { if !$0 { vaccineToDelete = nil } }),
            presenting: vaccineToDelete
        ) { vaccine in
            Button("Delete", role: .destructive) {
                context.delete(vaccine)
            }
            Button("Cancel", role: .cancel) {}
        } message: { vaccine in
            Text("\"\(vaccine.name)\" will be deleted. This can't be undone.")
        }
    }
}
