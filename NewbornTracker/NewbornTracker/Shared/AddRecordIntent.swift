import AppIntents
import Foundation
import WidgetKit

/// The quick-add buttons of the home screen widget. The widget runs this itself, without opening the app.
struct AddRecordIntent: AppIntent {
    static let title: LocalizedStringResource = "Add record"
    static let isDiscoverable = false

    @Parameter(title: "Type")
    var typeID: String

    @Parameter(title: "Baby")
    var babyID: String

    init() {}

    init(type: RecordType, babyID: UUID) {
        self.typeID = type.rawValue
        self.babyID = babyID.uuidString
    }

    func perform() async throws -> some IntentResult {
        guard let type = RecordType(rawValue: typeID), let id = UUID(uuidString: babyID) else { return .result() }

        let container = try await MainActor.run { try AppSchema.makeContainer() }
        _ = try await RecordService(modelContainer: container).addRecord(type: type, occurredAt: .now, babyID: id)

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
