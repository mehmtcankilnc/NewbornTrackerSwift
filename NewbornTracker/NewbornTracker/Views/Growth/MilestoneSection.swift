import SwiftData
import SwiftUI

/// The milestone journal: the built-in list plus the moments the parent added.
struct MilestoneSection: View {
    let baby: Baby

    @Environment(\.modelContext) private var context
    @Query private var entries: [MilestoneEntry]
    @Query private var customMilestones: [CustomMilestone]
    @State private var selectedRow: MilestoneRow?
    @State private var isAddingCustom = false
    @State private var milestoneToDelete: CustomMilestone?

    init(baby: Baby) {
        self.baby = baby
        let babyID = baby.id
        _entries = Query(filter: #Predicate<MilestoneEntry> { $0.baby?.id == babyID })
        _customMilestones = Query(filter: #Predicate<CustomMilestone> { $0.baby?.id == babyID })
    }

    var body: some View {
        let rows = MilestoneChecklist.rows(entries: entries, customMilestones: customMilestones)

        VStack(alignment: .leading, spacing: 12) {
            Text("Every child develops at their own pace. These ages are a rough guide.")
                .scaledFont(size: 12)
                .foregroundStyle(Color.appMuted)

            AddEntryCard(
                symbol: "sparkles",
                title: "Add your own moment",
                hint: "Note down moments that are just yours, like a first laugh."
            ) {
                isAddingCustom = true
            }

            VStack(spacing: 8) {
                ForEach(rows) { row in
                    ChecklistRow(title: row.name, subtitle: subtitle(for: row), isDone: row.isDone) {
                        selectedRow = row
                    } leading: {
                        if let fileName = row.log?.photoFileName {
                            PhotoThumbnail(fileName: fileName)
                        } else {
                            CheckCircle(isDone: row.isDone)
                        }
                    }
                    .contextMenu {
                        if case .custom(let id) = row.source,
                           let milestone = customMilestones.first(where: { $0.id == id }) {
                            Button("Delete", systemImage: "trash", role: .destructive) { milestoneToDelete = milestone }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .sheet(item: $selectedRow) { row in
            MilestoneSheet(baby: baby, row: row) { selectedRow = nil }
        }
        .sheet(isPresented: $isAddingCustom) {
            CustomMilestoneSheet(baby: baby) { isAddingCustom = false }
        }
        .alert(
            "Delete this moment?",
            isPresented: Binding(get: { milestoneToDelete != nil }, set: { if !$0 { milestoneToDelete = nil } }),
            presenting: milestoneToDelete
        ) { milestone in
            Button("Delete", role: .destructive) {
                PhotoStorage.standard.delete(milestone.log?.photoFileName)
                context.delete(milestone)
            }
            Button("Cancel", role: .cancel) {}
        } message: { milestone in
            Text("\"\(milestone.name)\" will be deleted. This can't be undone.")
        }
    }

    private func subtitle(for row: MilestoneRow) -> String {
        guard let log = row.log else { return row.ageLabel }
        let date = log.achievedAt.formatted(.dateTime.day().month(.abbreviated).year())
        return String(localized: "Achieved on \(date)")
    }
}

/// A small square picture of a milestone photo, loaded from the app's photo folder.
private struct PhotoThumbnail: View {
    let fileName: String
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.appSurfaceElevated
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(.rect(cornerRadius: 10))
        .task(id: fileName) {
            image = PhotoStorage.standard.image(named: fileName)?.preparingThumbnail(of: CGSize(width: 120, height: 120))
        }
    }
}
