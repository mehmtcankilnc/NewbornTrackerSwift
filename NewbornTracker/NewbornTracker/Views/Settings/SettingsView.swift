import SwiftData
import SwiftUI

struct SettingsView: View {
    @Query(sort: \Baby.createdAt) private var babies: [Baby]
    @Environment(ActiveBabyStore.self) private var activeBabyStore
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearance") private var appearance = AppearanceMode.system
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    @State private var isAddingBaby = false
    @State private var babyToDelete: Baby?
    @State private var isConfirmingDeleteRecords = false

    var body: some View {
        let activeBaby = activeBabyStore.activeBaby(in: babies)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    babiesSection(activeBaby: activeBaby)

                    if let activeBaby {
                        ProfileSection(baby: activeBaby)
                            .id(activeBaby.id)
                    }

                    appearanceSection
                    notificationsSection

                    if activeBaby != nil {
                        dataSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.appSurface.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .tint(Color.appPrimary)
        .sheet(isPresented: $isAddingBaby) { AddBabySheet() }
        .alert(
            babies.count > 1 ? "Delete this baby?" : "Can't delete",
            isPresented: Binding(get: { babyToDelete != nil }, set: { if !$0 { babyToDelete = nil } }),
            presenting: babyToDelete
        ) { baby in
            if babies.count > 1 {
                Button("Delete", role: .destructive) {
                    context.deleteBaby(baby, among: babies)
                }
                Button("Cancel", role: .cancel) {}
            } else {
                Button("OK", role: .cancel) {}
            }
        } message: { baby in
            if babies.count > 1 {
                Text("\"\(baby.name)\" and all their records will be deleted. This can't be undone.")
            } else {
                Text("The last remaining baby profile can't be deleted.")
            }
        }
        .alert("Delete all records?", isPresented: $isConfirmingDeleteRecords) {
            Button("Delete all", role: .destructive) {
                if let activeBaby {
                    context.deleteAllRecords(of: activeBaby)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All poop, pee, feed, and sleep records will be deleted. The baby's name and settings are kept. This can't be undone.")
        }
    }

    private func babiesSection(activeBaby: Baby?) -> some View {
        SettingsSection(title: "Babies") {
            VStack(spacing: 8) {
                ForEach(babies) { baby in
                    BabyRow(baby: baby, isActive: baby.id == activeBaby?.id) {
                        activeBabyStore.select(baby)
                    }
                    .contextMenu {
                        Button("Delete", systemImage: "trash", role: .destructive) { babyToDelete = baby }
                    }
                }
                AddEntryCard(
                    symbol: "person.badge.plus",
                    title: "Add a new baby",
                    hint: "Keep multiple babies' records separate."
                ) {
                    isAddingBaby = true
                }
            }
        }
    }

    private var appearanceSection: some View {
        SettingsSection(title: "Appearance") {
            VStack(spacing: 8) {
                ForEach(AppearanceMode.allCases) { mode in
                    OptionPill(title: String(localized: mode.title), isSelected: appearance == mode) {
                        appearance = mode
                    }
                }
            }
        }
    }

    private var notificationsSection: some View {
        SettingsSection(title: "Notifications") {
            Toggle(isOn: $notificationsEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("App notifications")
                        .scaledFont(size: 16)
                        .foregroundStyle(Color.appInk)
                    Text("Show a notification while tracking sleep")
                        .scaledFont(size: 12)
                        .foregroundStyle(Color.appMuted)
                }
            }
            .tint(Color.appPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.appSurfaceElevated, in: .rect(cornerRadius: 16))
        }
    }

    private var dataSection: some View {
        SettingsSection(title: "Data") {
            Button {
                isConfirmingDeleteRecords = true
            } label: {
                Label("Delete all records", systemImage: "trash")
                    .scaledFont(size: 16, weight: .semibold)
                    .foregroundStyle(Color.appDanger)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    .background(Color.appSurfaceElevated, in: .capsule)
            }
            .buttonStyle(.pressableScale)
        }
    }
}
