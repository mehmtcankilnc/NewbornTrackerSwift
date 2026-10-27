import Foundation

/// The "mark as achieved" form: a date, a note and a photo.
/// It also keeps track of which photo files are no longer needed, so none are left behind on the disk.
struct MilestoneInput: Equatable {
    var achievedAt: Date
    var noteText: String
    private(set) var photoFileName: String?
    /// The photo that was already saved when the form opened.
    let originalPhotoFileName: String?

    init(now: Date = .now) {
        achievedAt = now
        noteText = ""
        photoFileName = nil
        originalPhotoFileName = nil
    }

    init(_ log: MilestoneLog) {
        achievedAt = log.achievedAt
        noteText = log.note ?? ""
        photoFileName = log.photoFileName
        originalPhotoFileName = log.photoFileName
    }

    var note: String? {
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var log: MilestoneLog {
        MilestoneLog(achievedAt: achievedAt, note: note, photoFileName: photoFileName)
    }

    /// Puts a photo in place of the current one, or removes it with nil.
    /// Returns a file to delete right away: a photo picked earlier in this same form and now replaced.
    /// The saved original stays on the disk until the form is saved.
    mutating func setPhoto(_ fileName: String?) -> String? {
        let previous = photoFileName
        photoFileName = fileName
        return previous != originalPhotoFileName ? previous : nil
    }

    /// When the form is saved, a replaced or removed original is no longer needed.
    var photosToDeleteOnSave: [String] {
        guard let originalPhotoFileName, originalPhotoFileName != photoFileName else { return [] }
        return [originalPhotoFileName]
    }

    /// When the form is closed without saving, a photo picked in it is no longer needed.
    var photoToDeleteOnCancel: String? {
        photoFileName != originalPhotoFileName ? photoFileName : nil
    }
}
