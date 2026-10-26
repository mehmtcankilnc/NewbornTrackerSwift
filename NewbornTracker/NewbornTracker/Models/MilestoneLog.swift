import Foundation

/// The journal entry for an achieved milestone: when, an optional note, an optional photo.
nonisolated struct MilestoneLog: Codable, Equatable {
    var achievedAt: Date
    var note: String?
    /// File name inside the app's photo folder, never an absolute path.
    var photoFileName: String?
}
