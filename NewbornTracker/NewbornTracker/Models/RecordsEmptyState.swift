import Foundation

/// Why the Records list has nothing to show, if it has nothing to show.
enum RecordsEmptyState: Equatable {
    case noRecords
    case noMatches

    init?(totalCount: Int, filteredCount: Int) {
        if totalCount == 0 {
            self = .noRecords
        } else if filteredCount == 0 {
            self = .noMatches
        } else {
            return nil
        }
    }
}
