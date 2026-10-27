nonisolated enum RecordType: String, Codable, CaseIterable, Identifiable {
    case poop, piss, feed, sleep, fever, medicine, vitamin

    var id: String { rawValue }

    static let primary: [RecordType] = [.poop, .piss, .feed, .sleep]

    static let health: [RecordType] = [.fever, .medicine, .vitamin]

    var isHealth: Bool { Self.health.contains(self) }
}
