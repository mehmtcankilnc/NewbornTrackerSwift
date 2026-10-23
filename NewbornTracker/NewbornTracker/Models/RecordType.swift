enum RecordType: String, CaseIterable, Identifiable {
    case poop, piss, feed, sleep, fever, medicine, vitamin

    var id: String { rawValue }
}
