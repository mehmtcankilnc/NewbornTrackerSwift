import Foundation
import SwiftData

extension Baby {
    /// Every photo file this baby's milestones point to.
    var photoFileNames: [String] {
        milestoneEntries.compactMap { $0.log.photoFileName }
            + customMilestones.compactMap { $0.log?.photoFileName }
    }
}

extension ModelContext {
    /// Deletes a baby with everything that belongs to them, photo files included.
    /// The last remaining baby is never deleted. Returns whether anything was deleted.
    @discardableResult
    func deleteBaby(_ baby: Baby, among babies: [Baby], photos: PhotoStorage = .standard) -> Bool {
        guard babies.count > 1 else { return false }
        baby.photoFileNames.forEach { photos.delete($0) }
        delete(baby)
        return true
    }

    /// Deletes the baby's records and stops a running sleep. The profile, growth, vaccines and milestones stay.
    func deleteAllRecords(of baby: Baby) {
        baby.records.forEach { delete($0) }
        baby.activeSleep = nil
    }
}
