enum Gender: String, Codable, CaseIterable, Identifiable {
    case male, female

    var id: String { rawValue }
}
