import Foundation

/// What the pure logic (stats, grouping, filters) needs to know about a record.
protocol LoggedRecord {
    var type: RecordType { get }
    var occurredAt: Date { get }
    var durationMinutes: Int? { get }
}

extension BabyRecord: LoggedRecord {}
extension RecordValue: LoggedRecord {}
