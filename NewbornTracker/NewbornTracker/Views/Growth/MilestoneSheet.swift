import PhotosUI
import SwiftData
import SwiftUI

/// Mark a milestone as achieved: a date, a note and a photo. Also edits and clears a saved entry.
struct MilestoneSheet: View {
    let baby: Baby
    let row: MilestoneRow
    let onClose: () -> Void

    @Environment(\.modelContext) private var context
    @State private var input: MilestoneInput
    @State private var pickerItem: PhotosPickerItem?
    @State private var photoFailed = false
    @State private var isCommitted = false

    private let photos = PhotoStorage.standard

    init(baby: Baby, row: MilestoneRow, onClose: @escaping () -> Void) {
        self.baby = baby
        self.row = row
        self.onClose = onClose
        _input = State(initialValue: row.log.map { MilestoneInput($0) } ?? MilestoneInput())
    }

    var body: some View {
        SheetScaffold(title: LocalizedStringResource(stringLiteral: row.name), fixedHeight: 540) {
            HStack {
                Text("Date")
                    .scaledFont(size: 14)
                    .foregroundStyle(Color.appMuted)
                Spacer()
                DatePicker("", selection: $input.achievedAt, in: ...Date.now, displayedComponents: .date)
                    .labelsHidden()
                    .tint(Color.appPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.appSurfaceElevated, in: .rect(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 6) {
                Text("Note (optional)")
                    .scaledFont(size: 12, weight: .semibold)
                    .foregroundStyle(Color.appMuted)
                TextField("A few words about this moment...", text: $input.noteText, axis: .vertical)
                    .lineLimit(3...5)
                    .scaledFont(size: 16)
                    .foregroundStyle(Color.appInk)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: 88, alignment: .topLeading)
                    .background(Color.appSurfaceElevated, in: .rect(cornerRadius: 16))
                    .onChange(of: input.noteText) { _, newValue in
                        input.noteText = String(newValue.prefix(200))
                    }
            }

            photoPicker
                .onChange(of: pickerItem) { _, item in
                    guard let item else { return }
                    Task { await loadPhoto(from: item) }
                }
                .onDisappear {
                    // Closed without saving (Cancel or swipe down): drop a photo picked in this form.
                    if !isCommitted {
                        photos.delete(input.photoToDeleteOnCancel)
                    }
                }

            VStack(spacing: 12) {
                PillButton(title: "Save") { save() }

                if row.isDone {
                    PillButton(title: "Delete", style: .destructive) { clear() }
                }

                PillButton(title: "Cancel", style: .secondary, action: onClose)
            }
        }
    }

    @ViewBuilder
    private var photoPicker: some View {
        if let fileName = input.photoFileName, let image = photos.image(named: fileName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .clipShape(.rect(cornerRadius: 16))
                .overlay(alignment: .topTrailing) {
                    Button {
                        photos.delete(input.setPhoto(nil))
                    } label: {
                        Image(systemName: "xmark")
                            .scaledFont(size: 13, weight: .bold)
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(.black.opacity(0.5), in: .circle)
                    }
                    .padding(8)
                    .accessibilityLabel("Remove photo")
                }
        } else {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label("Add photo", systemImage: "photo")
                    .scaledFont(size: 14, weight: .semibold)
                    .foregroundStyle(Color.appMuted)
                    .frame(maxWidth: .infinity, minHeight: 140)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.appBorder, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    )
            }
        }

        if photoFailed {
            Text("This photo could not be loaded.")
                .scaledFont(size: 12)
                .foregroundStyle(Color.appDanger)
        }
    }

    private func loadPhoto(from item: PhotosPickerItem) async {
        photoFailed = false
        defer { pickerItem = nil }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let fileName = try? photos.save(imageData: data)
        else {
            photoFailed = true
            return
        }
        photos.delete(input.setPhoto(fileName))
    }

    private func save() {
        context.saveMilestone(input.log, for: row.source, baby: baby)
        input.photosToDeleteOnSave.forEach { photos.delete($0) }
        isCommitted = true
        onClose()
    }

    private func clear() {
        context.clearMilestone(row.source, baby: baby)
        photos.delete(input.originalPhotoFileName)
        // A photo picked in this form but not saved goes too.
        photos.delete(input.photoToDeleteOnCancel)
        isCommitted = true
        onClose()
    }
}
