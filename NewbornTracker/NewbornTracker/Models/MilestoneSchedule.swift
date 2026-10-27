import Foundation

/// A simplified, approximate list of developmental milestones. Every child develops at their own pace,
/// so this is a memory journal, not medical guidance.
enum MilestoneSchedule {
    static let items: [ScheduleItem] = [
        ScheduleItem(id: "first-smile", age: "Months 1-2", name: "First social smile"),
        ScheduleItem(id: "head-control", age: "Months 3-4", name: "Head control"),
        ScheduleItem(id: "rolling-over", age: "Months 4-6", name: "Rolling over"),
        ScheduleItem(id: "sitting-unassisted", age: "Months 6-8", name: "Sitting without support"),
        ScheduleItem(id: "first-tooth", age: "Months 6-10", name: "First tooth"),
        ScheduleItem(id: "crawling", age: "Months 7-10", name: "Crawling"),
        ScheduleItem(id: "pulling-to-stand", age: "Months 8-10", name: "Pulling up to stand"),
        ScheduleItem(id: "first-word", age: "Months 9-14", name: "First word"),
        ScheduleItem(id: "first-steps", age: "Months 9-15", name: "First steps"),
        ScheduleItem(id: "walking-alone", age: "Months 12-18", name: "Walking independently"),
        ScheduleItem(id: "first-sentence", age: "Months 18-24", name: "First sentence"),
        ScheduleItem(id: "running", age: "Months 18-24", name: "Running"),
    ]
}
