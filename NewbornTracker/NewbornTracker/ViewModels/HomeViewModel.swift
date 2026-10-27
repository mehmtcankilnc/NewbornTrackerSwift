import Foundation
import Observation

/// The state machine behind the Home screen: which sheet is open, and what gets saved.
@Observable
final class HomeViewModel {
    enum Sheet: Identifiable, Equatable {
        case time(RecordType)
        case feedDetails(occurredAt: Date)
        case healthPicker
        case healthDetails(type: RecordType, occurredAt: Date)
        case stopSleep

        var id: String {
            switch self {
            case .time(let type): "time-\(type.rawValue)"
            case .feedDetails: "feedDetails"
            case .healthPicker: "healthPicker"
            case .healthDetails(let type, _): "healthDetails-\(type.rawValue)"
            case .stopSleep: "stopSleep"
            }
        }
    }

    /// What the view has to do after a step. The view model never touches the database.
    enum Action: Equatable {
        case save(RecordDraft)
        case startSleep(at: Date)
        case finishSleep(at: Date)
    }

    struct SavedToast: Equatable {
        let id = UUID()
        let type: RecordType
        let time: Date
    }

    var sheet: Sheet?
    private(set) var toast: SavedToast?

    func cardTapped(_ type: RecordType, isSleeping: Bool) {
        sheet = (type == .sleep && isSleeping) ? .stopSleep : .time(type)
    }

    func healthCardTapped() {
        sheet = .healthPicker
    }

    func healthTypePicked(_ type: RecordType) {
        sheet = .time(type)
    }

    func timePicked(_ time: Date) -> Action? {
        guard case .time(let type) = sheet else { return nil }

        switch type {
        case .sleep:
            sheet = nil
            return .startSleep(at: time)
        case .feed:
            sheet = .feedDetails(occurredAt: time)
            return nil
        case .fever, .medicine, .vitamin:
            sheet = .healthDetails(type: type, occurredAt: time)
            return nil
        case .poop, .piss:
            return save(RecordDraft(type: type, occurredAt: time))
        }
    }

    func feedConfirmed(_ input: FeedDetailsInput) -> Action? {
        guard case .feedDetails(let time) = sheet, let draft = input.draft(at: time) else { return nil }
        return save(draft)
    }

    func healthConfirmed(_ input: HealthDetailsInput) -> Action? {
        guard case .healthDetails(_, let time) = sheet, let draft = input.draft(at: time) else { return nil }
        return save(draft)
    }

    func stopSleepConfirmed(at endedAt: Date = .now) -> Action? {
        guard sheet == .stopSleep else { return nil }
        sheet = nil
        return .finishSleep(at: endedAt)
    }

    func dismiss() {
        sheet = nil
    }

    func clearToast() {
        toast = nil
    }

    private func save(_ draft: RecordDraft) -> Action {
        sheet = nil
        toast = SavedToast(type: draft.type, time: draft.occurredAt)
        return .save(draft)
    }
}
