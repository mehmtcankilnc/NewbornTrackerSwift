import Foundation
import Observation

/// Remembers which baby the app is showing. Only the id is stored; the babies live in SwiftData.
@Observable
final class ActiveBabyStore {
    static let defaultsKey = "activeBabyID"

    private let defaults: UserDefaults
    private(set) var activeBabyID: UUID?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.activeBabyID = defaults.string(forKey: Self.defaultsKey).flatMap(UUID.init(uuidString:))
    }

    func select(_ baby: Baby) {
        activeBabyID = baby.id
        defaults.set(baby.id.uuidString, forKey: Self.defaultsKey)
    }

    /// The selected baby, or the first one when nothing valid is selected.
    func activeBaby(in babies: [Baby]) -> Baby? {
        babies.first { $0.id == activeBabyID } ?? babies.first
    }
}
