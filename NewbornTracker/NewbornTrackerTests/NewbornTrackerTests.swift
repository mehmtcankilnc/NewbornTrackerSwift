import Foundation
import Testing
import SwiftData
import UserNotifications
@testable import NewbornTracker

private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!
    calendar.firstWeekday = 2
    return calendar
}()

private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
    let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
    return calendar.date(from: components)!
}

@MainActor
struct RecordTypeTests {
    @Test func primaryAndHealthPartitionAllTypes() {
        let combined = RecordType.primary + RecordType.health

        #expect(combined.count == RecordType.allCases.count)
        #expect(Set(combined) == Set(RecordType.allCases))
    }

    @Test func healthTypesAreExactlyFeverMedicineVitamin() {
        #expect(RecordType.health == [.fever, .medicine, .vitamin])
        #expect(RecordType.allCases.filter(\.isHealth) == RecordType.health)
    }

    @Test(arguments: RecordType.allCases)
    func everyTypeRoundTripsThroughItsRawValue(type: RecordType) {
        #expect(RecordType(rawValue: type.rawValue) == type)
    }

    @Test func unknownRawValueIsNil() {
        #expect(RecordType(rawValue: "nap") == nil)
    }
}

@MainActor
struct FeedSubtypeTests {
    @Test func rawValuesStayStable() {
        #expect(FeedSubtype.breastfeeding.rawValue == "breastfeeding")
        #expect(FeedSubtype.extraBreastMilk.rawValue == "extra_breast_milk")
        #expect(FeedSubtype.extraFormula.rawValue == "extra_formula")
    }
}

@MainActor
struct TodayStatsTests {
    /// A fixed "now" so tests never depend on the real clock: 2026-03-10 14:00 Istanbul.
    private var now: Date { date(2026, 3, 10, 14, 0) }

    private func stats(for records: [RecordValue]) -> TodayStats {
        TodayStats(records: records, now: now, calendar: calendar)
    }

    @Test func emptyListGivesZeros() {
        let result = stats(for: [])

        #expect(result.sleepMinutes == 0)
        for type in RecordType.allCases {
            #expect(result.count(for: type) == 0)
        }
    }

    @Test func countsEachTypeSeparately() {
        let records = [
            RecordValue(type: .poop, occurredAt: date(2026, 3, 10, 8, 0)),
            RecordValue(type: .poop, occurredAt: date(2026, 3, 10, 11, 30)),
            RecordValue(type: .feed, occurredAt: date(2026, 3, 10, 9, 0)),
        ]

        let result = stats(for: records)

        #expect(result.count(for: .poop) == 2)
        #expect(result.count(for: .feed) == 1)
        #expect(result.count(for: .piss) == 0)
    }

    @Test func dayBoundariesAreInclusiveAtMidnightAndExclusiveBefore() {
        let records = [
            RecordValue(type: .piss, occurredAt: date(2026, 3, 9, 23, 59)),
            RecordValue(type: .piss, occurredAt: date(2026, 3, 10, 0, 0)),
            RecordValue(type: .piss, occurredAt: date(2026, 3, 10, 23, 59)),
            RecordValue(type: .piss, occurredAt: date(2026, 3, 11, 0, 0)),
        ]

        #expect(stats(for: records).count(for: .piss) == 2)
    }

    @Test func sleepMinutesAreSummedAndMissingDurationCountsAsZero() {
        let records = [
            RecordValue(type: .sleep, occurredAt: date(2026, 3, 10, 1, 0), durationMinutes: 90),
            RecordValue(type: .sleep, occurredAt: date(2026, 3, 10, 12, 0), durationMinutes: 45),
            RecordValue(type: .sleep, occurredAt: date(2026, 3, 10, 13, 0)),
            RecordValue(type: .sleep, occurredAt: date(2026, 3, 9, 20, 0), durationMinutes: 600),
        ]

        let result = stats(for: records)

        #expect(result.sleepMinutes == 135)
        #expect(result.count(for: .sleep) == 3)
    }

    @Test func durationOnNonSleepRecordsIsIgnored() {
        let record = RecordValue(type: .feed, occurredAt: date(2026, 3, 10, 9, 0), durationMinutes: 20)

        #expect(stats(for: [record]).sleepMinutes == 0)
    }

    @Test func sameInstantFallsOnDifferentDaysInDifferentTimeZones() {
        // 2026-03-10 22:30 UTC is already 01:30 on the 11th in Istanbul (UTC+3).
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let instant = Date(timeIntervalSince1970: 1_773_181_800) // 2026-03-10 22:30 UTC
        let record = RecordValue(type: .poop, occurredAt: instant)

        let utcNow = utc.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 12))!
        let inUTC = TodayStats(records: [record], now: utcNow, calendar: utc)
        let inIstanbul = TodayStats(records: [record], now: utcNow, calendar: calendar)

        #expect(inUTC.count(for: .poop) == 1)
        #expect(inIstanbul.count(for: .poop) == 0)
    }
}


@MainActor
struct DayGrouperTests {
    @Test func emptyInputGivesNoSections() {
        #expect(DayGrouper.group([RecordValue](), calendar: calendar).isEmpty)
    }

    @Test func groupsByDayWithNewestDayFirst() {
        let records = [
            RecordValue(type: .poop, occurredAt: date(2026, 3, 8, 10, 0)),
            RecordValue(type: .piss, occurredAt: date(2026, 3, 10, 9, 0)),
            RecordValue(type: .feed, occurredAt: date(2026, 3, 8, 22, 0)),
            RecordValue(type: .poop, occurredAt: date(2026, 3, 10, 18, 0)),
        ]

        let sections = DayGrouper.group(records, calendar: calendar)

        #expect(sections.map(\.day) == [date(2026, 3, 10), date(2026, 3, 8)])
        #expect(sections.map(\.records.count) == [2, 2])
    }

    @Test func sortsRecordsWithinADayNewestFirst() {
        let records = [
            RecordValue(type: .poop, occurredAt: date(2026, 3, 10, 8, 0)),
            RecordValue(type: .poop, occurredAt: date(2026, 3, 10, 20, 0)),
            RecordValue(type: .poop, occurredAt: date(2026, 3, 10, 12, 0)),
        ]

        let sections = DayGrouper.group(records, calendar: calendar)

        #expect(sections.first?.records.map(\.occurredAt) == [
            date(2026, 3, 10, 20, 0),
            date(2026, 3, 10, 12, 0),
            date(2026, 3, 10, 8, 0),
        ])
    }

    @Test func midnightStartsANewDay() {
        let records = [
            RecordValue(type: .sleep, occurredAt: date(2026, 3, 9, 23, 59)),
            RecordValue(type: .sleep, occurredAt: date(2026, 3, 10, 0, 0)),
        ]

        #expect(DayGrouper.group(records, calendar: calendar).count == 2)
    }

    @Test func headingIsTodayForTheSameDay() {
        let now = date(2026, 3, 10, 14, 0)

        #expect(DayGrouper.heading(for: date(2026, 3, 10), now: now, calendar: calendar) == .today)
    }

    @Test func headingIsYesterdayForThePreviousDay() {
        let now = date(2026, 3, 10, 0, 5)

        #expect(DayGrouper.heading(for: date(2026, 3, 9), now: now, calendar: calendar) == .yesterday)
    }

    @Test func yesterdayWorksAcrossAMonthBoundary() {
        let now = date(2026, 3, 1, 9, 0)

        #expect(DayGrouper.heading(for: date(2026, 2, 28), now: now, calendar: calendar) == .yesterday)
    }

    @Test func olderDaysKeepTheirDate() {
        let now = date(2026, 3, 10, 14, 0)
        let older = date(2026, 3, 7)

        #expect(DayGrouper.heading(for: older, now: now, calendar: calendar) == .date(older))
    }
}

@MainActor
struct PeriodTests {
    private var now: Date { date(2026, 3, 10, 14, 0) }

    private func contains(_ period: Period, _ day: Date) -> Bool {
        period.contains(day, now: now, calendar: calendar)
    }

    @Test func allContainsEverything() {
        #expect(contains(.all, date(1999, 1, 1)))
        #expect(contains(.all, date(2040, 12, 31)))
    }

    @Test func todayCoversTheWholeCalendarDay() {
        #expect(contains(.today, date(2026, 3, 10, 0, 0)))
        #expect(contains(.today, date(2026, 3, 10, 23, 59)))
        #expect(!contains(.today, date(2026, 3, 9, 23, 59)))
        #expect(!contains(.today, date(2026, 3, 11, 0, 0)))
    }

    @Test func weekRunsFromMondayToSundayInclusive() {
        #expect(contains(.week, date(2026, 3, 9, 0, 0)))
        #expect(contains(.week, date(2026, 3, 15, 23, 59)))
        #expect(!contains(.week, date(2026, 3, 8, 23, 59)))
        #expect(!contains(.week, date(2026, 3, 16, 0, 0)))
    }

    @Test func weekStartFollowsTheCalendar() {
        var sundayFirst = calendar
        sundayFirst.firstWeekday = 1

        let sunday = date(2026, 3, 8, 12, 0)

        #expect(!Period.week.contains(sunday, now: now, calendar: calendar))
        #expect(Period.week.contains(sunday, now: now, calendar: sundayFirst))
    }

    @Test func monthMatchesYearAndMonth() {
        #expect(contains(.month, date(2026, 3, 1, 0, 0)))
        #expect(contains(.month, date(2026, 3, 31, 23, 59)))
        #expect(!contains(.month, date(2026, 2, 28, 23, 59)))
        #expect(!contains(.month, date(2026, 4, 1, 0, 0)))
        #expect(!contains(.month, date(2025, 3, 10, 14, 0)))
    }

    @Test func customRangeIncludesBothWholeDays() {
        let period = Period.custom(from: date(2026, 3, 1, 15, 0), to: date(2026, 3, 3, 9, 0))

        #expect(contains(period, date(2026, 3, 1, 0, 0)))
        #expect(contains(period, date(2026, 3, 3, 23, 59)))
        #expect(!contains(period, date(2026, 2, 28, 23, 59)))
        #expect(!contains(period, date(2026, 3, 4, 0, 0)))
    }

    @Test func customRangeWithReversedBoundsStillWorks() {
        let period = Period.custom(from: date(2026, 3, 3), to: date(2026, 3, 1))

        #expect(contains(period, date(2026, 3, 2, 12, 0)))
    }

    @Test func customRangeOfASingleDayIsThatDay() {
        let period = Period.custom(from: date(2026, 3, 5), to: date(2026, 3, 5))

        #expect(contains(period, date(2026, 3, 5, 23, 30)))
        #expect(!contains(period, date(2026, 3, 6, 0, 0)))
    }
}

@MainActor
struct RecordFilterTests {
    private var now: Date { date(2026, 3, 10, 14, 0) }

    private let records = [
        RecordValue(type: .poop, occurredAt: date(2026, 3, 10, 8, 0)),
        RecordValue(type: .feed, occurredAt: date(2026, 3, 10, 9, 0)),
        RecordValue(type: .fever, occurredAt: date(2026, 3, 10, 10, 0)),
        RecordValue(type: .feed, occurredAt: date(2026, 3, 8, 9, 0)),
    ]

    private func apply(_ filter: RecordFilter) -> [RecordValue] {
        filter.apply(to: records, now: now, calendar: calendar)
    }

    @Test func emptyTypeSetMatchesEveryType() {
        #expect(apply(RecordFilter(period: .all)) == records)
    }

    @Test func typeFilterKeepsOnlySelectedTypes() {
        let result = apply(RecordFilter(types: [.feed, .fever], period: .all))

        #expect(result.map(\.type) == [.feed, .fever, .feed])
    }

    @Test func periodFilterKeepsOnlyMatchingDays() {
        let result = apply(RecordFilter(period: .today))

        #expect(result.count == 3)
    }

    @Test func typeAndPeriodAreCombined() {
        let result = apply(RecordFilter(types: [.feed], period: .today))

        #expect(result == [records[1]])
    }

    @Test func applyPreservesInputOrder() {
        let result = apply(RecordFilter(period: .all))

        #expect(result.map(\.id) == records.map(\.id))
    }

    @Test func isActiveIsFalseOnlyForAllTypesAndAllTime() {
        #expect(!RecordFilter(period: .all).isActive)
        #expect(RecordFilter(types: [.poop], period: .all).isActive)
        #expect(RecordFilter(period: .week).isActive)
        #expect(RecordFilter().isActive)
    }
}

@MainActor
struct DurationTextTests {
    private let english = Locale(identifier: "en_US")
    private let turkish = Locale(identifier: "tr_TR")

    @Test(arguments: [
        (0, "0 min"),
        (1, "1 min"),
        (45, "45 min"),
        (60, "1 hr"),
        (125, "2 hr, 5 min"),
        (1500, "25 hr"),
    ])
    func regularStyleInEnglish(minutes: Int, expected: String) {
        #expect(DurationText.string(minutes: minutes, locale: english) == expected)
    }

    @Test(arguments: [
        (45, "45m"),
        (60, "1h"),
        (125, "2h 5m"),
    ])
    func compactStyleInEnglish(minutes: Int, expected: String) {
        #expect(DurationText.string(minutes: minutes, style: .compact, locale: english) == expected)
    }

    @Test func outputFollowsTheLocale() {
        let result = DurationText.string(minutes: 125, locale: turkish)

        #expect(result != DurationText.string(minutes: 125, locale: english))
        #expect(result.contains("sa"))
        #expect(result.contains("dk"))
    }
}

@MainActor
struct RecordTimeTests {
    private var now: Date { date(2026, 3, 10, 14, 0) }

    @Test func quickPickStartsWithNowAndIncreases() {
        let minutes = RecordTime.quickPickMinutes

        #expect(minutes.first == 0)
        #expect(minutes == minutes.sorted())
        #expect(Set(minutes).count == minutes.count)
    }

    @Test func minutesAgoSubtractsFromNow() {
        #expect(RecordTime.date(minutesAgo: 0, now: now) == now)
        #expect(RecordTime.date(minutesAgo: 30, now: now) == date(2026, 3, 10, 13, 30))
    }

    @Test func minutesAgoCrossesMidnight() {
        let justAfterMidnight = date(2026, 3, 10, 0, 20)

        #expect(RecordTime.date(minutesAgo: 60, now: justAfterMidnight) == date(2026, 3, 9, 23, 20))
    }

    @Test func earlierTimeStaysToday() {
        let picked = date(2000, 1, 1, 9, 30)

        #expect(RecordTime.today(at: picked, now: now, calendar: calendar) == date(2026, 3, 10, 9, 30))
    }

    @Test func laterTimeMeansYesterday() {
        let picked = date(2000, 1, 1, 20, 0)

        #expect(RecordTime.today(at: picked, now: now, calendar: calendar) == date(2026, 3, 9, 20, 0))
    }

    @Test func currentMinuteStaysToday() {
        let nowWithSeconds = now.addingTimeInterval(37)
        let picked = date(2000, 1, 1, 14, 0)

        #expect(RecordTime.today(at: picked, now: nowWithSeconds, calendar: calendar) == date(2026, 3, 10, 14, 0))
    }

    @Test func yesterdayRollsBackAcrossAMonthBoundary() {
        let firstOfMarch = date(2026, 3, 1, 10, 0)
        let picked = date(2000, 1, 1, 18, 0)

        #expect(RecordTime.today(at: picked, now: firstOfMarch, calendar: calendar) == date(2026, 2, 28, 18, 0))
    }
}

@MainActor
private func makeContainer() throws -> ModelContainer {
    try AppSchema.makeContainer(inMemory: true)
}

@MainActor
struct SwiftDataModelTests {
    @Test func recordRoundTripsThroughTheStore() throws {
        let container = try makeContainer()
        let baby = Baby(name: "Ada", birthDate: date(2026, 1, 5), gender: .female)
        let record = BabyRecord(
            type: .feed, occurredAt: date(2026, 3, 10, 9, 0),
            feedSubtypes: [.breastfeeding, .extraFormula], amountMl: 90
        )
        record.baby = baby
        container.mainContext.insert(baby)
        try container.mainContext.save()

        let freshContext = ModelContext(container)
        let fetched = try freshContext.fetch(FetchDescriptor<BabyRecord>())

        #expect(fetched.count == 1)
        #expect(fetched.first?.type == .feed)
        #expect(fetched.first?.feedSubtypes == [.breastfeeding, .extraFormula])
        #expect(fetched.first?.amountMl == 90)
        #expect(fetched.first?.baby?.name == "Ada")
        #expect(fetched.first?.baby?.gender == .female)
    }

    @Test func settingTheBabyUpdatesTheInverseRelationship() throws {
        let container = try makeContainer()
        let baby = Baby(name: "Ada")
        container.mainContext.insert(baby)

        let record = BabyRecord(type: .poop, occurredAt: date(2026, 3, 10, 9, 0))
        record.baby = baby

        #expect(baby.records.count == 1)
    }

    @Test func deletingABabyDeletesItsRecords() throws {
        let container = try makeContainer()
        let ada = Baby(name: "Ada")
        let bob = Baby(name: "Bob")
        container.mainContext.insert(ada)
        container.mainContext.insert(bob)
        BabyRecord(type: .poop, occurredAt: date(2026, 3, 10, 9, 0)).baby = ada
        BabyRecord(type: .piss, occurredAt: date(2026, 3, 10, 10, 0)).baby = ada
        BabyRecord(type: .feed, occurredAt: date(2026, 3, 10, 11, 0)).baby = bob
        try container.mainContext.save()

        container.mainContext.delete(ada)
        try container.mainContext.save()

        let remaining = try container.mainContext.fetch(FetchDescriptor<BabyRecord>())
        #expect(remaining.map(\.type) == [.feed])
    }

    @Test func activeSleepSurvivesASave() throws {
        let container = try makeContainer()
        let baby = Baby(name: "Ada")
        baby.activeSleep = ActiveSleep(startedAt: date(2026, 3, 10, 1, 0), notificationID: "n-1")
        container.mainContext.insert(baby)
        try container.mainContext.save()

        let fetched = try ModelContext(container).fetch(FetchDescriptor<Baby>())

        #expect(fetched.first?.activeSleep == ActiveSleep(startedAt: date(2026, 3, 10, 1, 0), notificationID: "n-1"))
    }
}

@MainActor
struct LoggedRecordTests {
    private var now: Date { date(2026, 3, 10, 14, 0) }

    private func sampleRecords() -> [BabyRecord] {
        [
            BabyRecord(type: .poop, occurredAt: date(2026, 3, 10, 8, 0)),
            BabyRecord(type: .sleep, occurredAt: date(2026, 3, 10, 1, 0), durationMinutes: 90),
            BabyRecord(type: .feed, occurredAt: date(2026, 3, 9, 9, 0)),
        ]
    }

    @Test func todayStatsWorkOnSwiftDataRecords() {
        let stats = TodayStats(records: sampleRecords(), now: now, calendar: calendar)

        #expect(stats.count(for: .poop) == 1)
        #expect(stats.count(for: .feed) == 0)
        #expect(stats.sleepMinutes == 90)
    }

    @Test func groupingKeepsTheSameRecordObjects() {
        let records = sampleRecords()

        let sections = DayGrouper.group(records, calendar: calendar)

        #expect(sections.count == 2)
        #expect(sections[0].records.first === records[0])
        #expect(sections[1].records.first === records[2])
    }

    @Test func filterWorksOnSwiftDataRecords() {
        let records = sampleRecords()

        let result = RecordFilter(types: [.poop, .feed], period: .all).apply(to: records, now: now, calendar: calendar)

        #expect(result.map(\.type) == [.poop, .feed])
    }

    @Test func plainValuesAndModelsGiveTheSameStats() {
        let values = [
            RecordValue(type: .sleep, occurredAt: date(2026, 3, 10, 1, 0), durationMinutes: 90),
            RecordValue(type: .poop, occurredAt: date(2026, 3, 10, 8, 0)),
        ]
        let models = [
            BabyRecord(type: .sleep, occurredAt: date(2026, 3, 10, 1, 0), durationMinutes: 90),
            BabyRecord(type: .poop, occurredAt: date(2026, 3, 10, 8, 0)),
        ]

        let fromValues = TodayStats(records: values, now: now, calendar: calendar)
        let fromModels = TodayStats(records: models, now: now, calendar: calendar)

        #expect(fromValues == fromModels)
    }
}

@MainActor
struct DevelopmentModelTests {
    @Test func developmentDataRoundTripsThroughTheStore() throws {
        let container = try makeContainer()
        let baby = Baby(name: "Ada")
        let log = MilestoneLog(achievedAt: date(2026, 3, 1), note: "Big smile", photoFileName: "a.jpg")
        container.mainContext.insert(baby)
        GrowthMeasurement(date: date(2026, 3, 1), weightKg: 4.2, heightCm: 55).baby = baby
        VaccineCompletion(scheduleID: "hepb-birth").baby = baby
        CustomVaccine(name: "Flu", ageLabel: "6 months", isCompleted: true).baby = baby
        MilestoneEntry(scheduleID: "first-smile", log: log).baby = baby
        CustomMilestone(name: "First laugh", log: nil).baby = baby
        try container.mainContext.save()

        let fetched = try ModelContext(container).fetch(FetchDescriptor<Baby>())
        let loaded = try #require(fetched.first)

        #expect(loaded.measurements.first?.weightKg == 4.2)
        #expect(loaded.measurements.first?.headCircumferenceCm == nil)
        #expect(loaded.vaccineCompletions.map(\.scheduleID) == ["hepb-birth"])
        #expect(loaded.customVaccines.first?.isCompleted == true)
        #expect(loaded.milestoneEntries.first?.log == log)
        #expect(loaded.customMilestones.first?.log == nil)
    }

    @Test func deletingABabyDeletesAllItsDevelopmentData() throws {
        let container = try makeContainer()
        let baby = Baby(name: "Ada")
        container.mainContext.insert(baby)
        BabyRecord(type: .poop, occurredAt: date(2026, 3, 1)).baby = baby
        GrowthMeasurement(date: date(2026, 3, 1), weightKg: 4.2).baby = baby
        VaccineCompletion(scheduleID: "hepb-birth").baby = baby
        CustomVaccine(name: "Flu").baby = baby
        MilestoneEntry(scheduleID: "first-smile", log: MilestoneLog(achievedAt: date(2026, 3, 1))).baby = baby
        CustomMilestone(name: "First laugh").baby = baby
        try container.mainContext.save()

        container.mainContext.delete(baby)
        try container.mainContext.save()

        let context = container.mainContext
        #expect(try context.fetchCount(FetchDescriptor<BabyRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<GrowthMeasurement>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<VaccineCompletion>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<CustomVaccine>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<MilestoneEntry>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<CustomMilestone>()) == 0)
    }

    @Test func removingACustomVaccineLeavesNoOrphanCompletion() throws {
        let container = try makeContainer()
        let baby = Baby(name: "Ada")
        container.mainContext.insert(baby)
        let flu = CustomVaccine(name: "Flu", isCompleted: true)
        flu.baby = baby
        VaccineCompletion(scheduleID: "hepb-birth").baby = baby
        try container.mainContext.save()

        container.mainContext.delete(flu)
        try container.mainContext.save()

        #expect(baby.customVaccines.isEmpty)
        #expect(baby.vaccineCompletions.count == 1)
    }
}

@MainActor
struct ActiveBabyStoreTests {
    private func withIsolatedDefaults(_ body: (UserDefaults) -> Void) {
        let name = "ActiveBabyStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        body(defaults)
    }

    @Test func noBabiesGivesNoActiveBaby() {
        withIsolatedDefaults { defaults in
            #expect(ActiveBabyStore(defaults: defaults).activeBaby(in: []) == nil)
        }
    }

    @Test func fallsBackToTheFirstBabyWhenNothingIsSelected() {
        withIsolatedDefaults { defaults in
            let ada = Baby(name: "Ada")
            let bob = Baby(name: "Bob")

            #expect(ActiveBabyStore(defaults: defaults).activeBaby(in: [ada, bob]) === ada)
        }
    }

    @Test func returnsTheSelectedBaby() {
        withIsolatedDefaults { defaults in
            let ada = Baby(name: "Ada")
            let bob = Baby(name: "Bob")
            let store = ActiveBabyStore(defaults: defaults)

            store.select(bob)

            #expect(store.activeBaby(in: [ada, bob]) === bob)
        }
    }

    @Test func fallsBackWhenTheSelectedBabyWasDeleted() {
        withIsolatedDefaults { defaults in
            let ada = Baby(name: "Ada")
            let bob = Baby(name: "Bob")
            let store = ActiveBabyStore(defaults: defaults)
            store.select(ada)

            #expect(store.activeBaby(in: [bob]) === bob)
        }
    }

    @Test func selectionSurvivesARelaunch() {
        withIsolatedDefaults { defaults in
            let ada = Baby(name: "Ada")
            ActiveBabyStore(defaults: defaults).select(ada)

            let relaunched = ActiveBabyStore(defaults: defaults)

            #expect(relaunched.activeBabyID == ada.id)
        }
    }

    @Test func garbageInDefaultsIsIgnored() {
        withIsolatedDefaults { defaults in
            defaults.set("not-a-uuid", forKey: ActiveBabyStore.defaultsKey)

            #expect(ActiveBabyStore(defaults: defaults).activeBabyID == nil)
        }
    }
}

@MainActor
struct RecordServiceTests {
    @Test func recordAddedInTheBackgroundIsVisibleOnTheMainContext() async throws {
        let container = try makeContainer()
        let baby = Baby(name: "Ada")
        container.mainContext.insert(baby)
        try container.mainContext.save()
        let service = RecordService(modelContainer: container)

        let value = try await service.addRecord(type: .poop, occurredAt: date(2026, 3, 10, 9, 0), babyID: baby.id)

        #expect(value.type == .poop)
        #expect(value.occurredAt == date(2026, 3, 10, 9, 0))
        let stored = try container.mainContext.fetch(FetchDescriptor<BabyRecord>())
        #expect(stored.count == 1)
        #expect(stored.first?.baby?.id == baby.id)
    }

    @Test func unknownBabyThrows() async throws {
        let container = try makeContainer()
        let service = RecordService(modelContainer: container)

        await #expect(throws: RecordServiceError.babyNotFound) {
            try await service.addRecord(type: .feed, occurredAt: .now, babyID: UUID())
        }
    }
}

@MainActor
struct HomeSummaryTests {
    private var now: Date { date(2026, 3, 10, 14, 0) }

    @Test func lastTimeComesFromTheLatestRecordNotTheListOrder() {
        let records = [
            RecordValue(type: .poop, occurredAt: date(2026, 3, 10, 8, 0)),
            RecordValue(type: .poop, occurredAt: date(2026, 3, 10, 12, 0)),
            RecordValue(type: .poop, occurredAt: date(2026, 3, 9, 20, 0)),
        ]

        let summary = HomeSummary(records: records, now: now, calendar: calendar)

        #expect(summary.lastTime(for: .poop) == date(2026, 3, 10, 12, 0))
        #expect(summary.count(for: .poop) == 2)
    }

    @Test func lastTimeLooksAtAllDaysButCountsOnlyToday() {
        let records = [RecordValue(type: .feed, occurredAt: date(2026, 3, 5, 9, 0))]

        let summary = HomeSummary(records: records, now: now, calendar: calendar)

        #expect(summary.count(for: .feed) == 0)
        #expect(summary.lastTime(for: .feed) == date(2026, 3, 5, 9, 0))
    }

    @Test func lastSleepTimeIsWhenItEnded() {
        let records = [
            RecordValue(type: .sleep, occurredAt: date(2026, 3, 10, 1, 0), endedAt: date(2026, 3, 10, 2, 30), durationMinutes: 90),
        ]

        let summary = HomeSummary(records: records, now: now, calendar: calendar)

        #expect(summary.lastTime(for: .sleep) == date(2026, 3, 10, 2, 30))
        #expect(summary.sleepMinutes == 90)
    }

    @Test func healthSummaryCombinesTheThreeHealthTypes() {
        let records = [
            RecordValue(type: .fever, occurredAt: date(2026, 3, 10, 7, 0)),
            RecordValue(type: .medicine, occurredAt: date(2026, 3, 10, 9, 0)),
            RecordValue(type: .vitamin, occurredAt: date(2026, 3, 9, 9, 0)),
            RecordValue(type: .poop, occurredAt: date(2026, 3, 10, 13, 0)),
        ]

        let summary = HomeSummary(records: records, now: now, calendar: calendar)

        #expect(summary.healthCountToday == 2)
        #expect(summary.lastHealthTime == date(2026, 3, 10, 9, 0))
    }

    @Test func emptyRecordsGiveEmptySummary() {
        let summary = HomeSummary(records: [RecordValue](), now: now, calendar: calendar)

        #expect(summary.lastTime(for: .poop) == nil)
        #expect(summary.lastHealthTime == nil)
        #expect(summary.healthCountToday == 0)
    }
}

@MainActor
struct DetailsInputTests {
    private let moment = date(2026, 3, 10, 9, 0)

    @Test func feedNeedsAtLeastOneSubtype() {
        let input = FeedDetailsInput()

        #expect(!input.canSave)
        #expect(input.draft(at: moment) == nil)
    }

    @Test func feedDraftKeepsSubtypeOrderAndParsesAmount() {
        var input = FeedDetailsInput(amountText: " 90 ")
        input.toggle(.extraFormula)
        input.toggle(.breastfeeding)

        let draft = input.draft(at: moment)

        #expect(draft?.feedSubtypes == [.breastfeeding, .extraFormula])
        #expect(draft?.amountMl == 90)
        #expect(draft?.type == .feed)
    }

    @Test func togglingTwiceRemovesTheSubtype() {
        var input = FeedDetailsInput()
        input.toggle(.breastfeeding)
        input.toggle(.breastfeeding)

        #expect(input.subtypes.isEmpty)
    }

    @Test(arguments: ["", "abc", "0", "-5", "9.5"])
    func invalidAmountIsIgnoredButFeedStillSaves(text: String) {
        var input = FeedDetailsInput(amountText: text)
        input.toggle(.breastfeeding)

        #expect(input.amountMl == nil)
        #expect(input.draft(at: moment)?.amountMl == nil)
    }

    @Test(arguments: [("38.5", 38.5), ("38,5", 38.5), (" 37 ", 37.0)])
    func feverAcceptsCommaAndDotDecimals(text: String, expected: Double) {
        let input = HealthDetailsInput(type: .fever, temperatureText: text)

        #expect(input.temperatureC == expected)
        #expect(input.draft(at: moment)?.temperatureC == expected)
    }

    @Test(arguments: ["", "hot", "0", "-1", "inf", "nan"])
    func feverRejectsInvalidTemperature(text: String) {
        let input = HealthDetailsInput(type: .fever, temperatureText: text)

        #expect(!input.canSave)
        #expect(input.draft(at: moment) == nil)
    }

    @Test func medicineNeedsATrimmedNote() {
        #expect(HealthDetailsInput(type: .medicine, noteText: "   ").draft(at: moment) == nil)

        let draft = HealthDetailsInput(type: .medicine, noteText: "  Paracetamol 5ml ").draft(at: moment)

        #expect(draft?.note == "Paracetamol 5ml")
        #expect(draft?.temperatureC == nil)
    }

    @Test func vitaminIgnoresTheTemperatureField() {
        let input = HealthDetailsInput(type: .vitamin, temperatureText: "38", noteText: "D3")

        #expect(input.draft(at: moment)?.temperatureC == nil)
        #expect(input.draft(at: moment)?.note == "D3")
    }
}

@MainActor
struct SleepTimerTests {
    private let start = date(2026, 3, 10, 1, 0)

    @Test func elapsedMinutesRoundToTheNearestMinute() {
        let sleep = ActiveSleep(startedAt: start, notificationID: nil)

        #expect(SleepTimer.elapsedMinutes(of: sleep, now: start.addingTimeInterval(89 * 60 + 20)) == 89)
        #expect(SleepTimer.elapsedMinutes(of: sleep, now: start.addingTimeInterval(89 * 60 + 40)) == 90)
    }

    @Test func elapsedMinutesNeverGoNegative() {
        let sleep = ActiveSleep(startedAt: start, notificationID: nil)

        #expect(SleepTimer.elapsedMinutes(of: sleep, now: start.addingTimeInterval(-300)) == 0)
    }

    @Test func finishedDraftHasStartEndAndDuration() {
        let sleep = ActiveSleep(startedAt: start, notificationID: nil)

        let draft = SleepTimer.finishedDraft(for: sleep, endedAt: date(2026, 3, 10, 2, 30))

        #expect(draft.type == .sleep)
        #expect(draft.occurredAt == start)
        #expect(draft.endedAt == date(2026, 3, 10, 2, 30))
        #expect(draft.durationMinutes == 90)
    }

    @Test func aVeryShortSleepStillLastsOneMinute() {
        let sleep = ActiveSleep(startedAt: start, notificationID: nil)

        #expect(SleepTimer.finishedDraft(for: sleep, endedAt: start).durationMinutes == 1)
    }
}

@MainActor
struct RecordWritingTests {
    @Test func insertedDraftBecomesARecordOfTheBaby() throws {
        let container = try makeContainer()
        let baby = Baby(name: "Ada")
        container.mainContext.insert(baby)
        let draft = RecordDraft(type: .feed, occurredAt: date(2026, 3, 10, 9, 0), feedSubtypes: [.breastfeeding], amountMl: 90)

        container.mainContext.insertRecord(draft, for: baby)
        try container.mainContext.save()

        let stored = try ModelContext(container).fetch(FetchDescriptor<BabyRecord>())
        #expect(stored.count == 1)
        #expect(stored.first?.amountMl == 90)
        #expect(stored.first?.feedSubtypes == [.breastfeeding])
        #expect(stored.first?.baby?.name == "Ada")
    }

    @Test func finishingASleepSavesARecordAndClearsTheActiveSleep() throws {
        let container = try makeContainer()
        let baby = Baby(name: "Ada")
        container.mainContext.insert(baby)
        baby.activeSleep = ActiveSleep(startedAt: date(2026, 3, 10, 1, 0), notificationID: "n-1")

        let record = container.mainContext.finishSleep(of: baby, endedAt: date(2026, 3, 10, 2, 30))

        #expect(baby.activeSleep == nil)
        #expect(record?.durationMinutes == 90)
        #expect(record?.endedAt == date(2026, 3, 10, 2, 30))
        #expect(baby.records.count == 1)
    }

    @Test func finishingWithoutAnActiveSleepDoesNothing() throws {
        let container = try makeContainer()
        let baby = Baby(name: "Ada")
        container.mainContext.insert(baby)

        #expect(container.mainContext.finishSleep(of: baby) == nil)
        #expect(baby.records.isEmpty)
    }
}

@MainActor
struct HomeViewModelTests {
    private let moment = date(2026, 3, 10, 9, 0)

    @Test(arguments: [RecordType.poop, .piss])
    func simpleTypesSaveRightAfterThePickedTime(type: RecordType) {
        let viewModel = HomeViewModel()
        viewModel.cardTapped(type, isSleeping: false)
        #expect(viewModel.sheet == .time(type))

        let action = viewModel.timePicked(moment)

        #expect(action == .save(RecordDraft(type: type, occurredAt: moment)))
        #expect(viewModel.sheet == nil)
        #expect(viewModel.toast?.type == type)
        #expect(viewModel.toast?.time == moment)
    }

    @Test func feedAsksForDetailsBeforeSaving() {
        let viewModel = HomeViewModel()
        viewModel.cardTapped(.feed, isSleeping: false)

        #expect(viewModel.timePicked(moment) == nil)
        #expect(viewModel.sheet == .feedDetails(occurredAt: moment))
        #expect(viewModel.toast == nil)

        var input = FeedDetailsInput(amountText: "80")
        input.toggle(.extraFormula)
        let action = viewModel.feedConfirmed(input)

        #expect(action == .save(RecordDraft(type: .feed, occurredAt: moment, feedSubtypes: [.extraFormula], amountMl: 80)))
        #expect(viewModel.sheet == nil)
        #expect(viewModel.toast?.type == .feed)
    }

    @Test func invalidFeedDetailsKeepTheSheetOpen() {
        let viewModel = HomeViewModel()
        viewModel.cardTapped(.feed, isSleeping: false)
        _ = viewModel.timePicked(moment)

        #expect(viewModel.feedConfirmed(FeedDetailsInput()) == nil)
        #expect(viewModel.sheet == .feedDetails(occurredAt: moment))
    }

    @Test func healthFlowGoesPickerThenTimeThenDetails() {
        let viewModel = HomeViewModel()

        viewModel.healthCardTapped()
        #expect(viewModel.sheet == .healthPicker)

        viewModel.healthTypePicked(.fever)
        #expect(viewModel.sheet == .time(.fever))

        #expect(viewModel.timePicked(moment) == nil)
        #expect(viewModel.sheet == .healthDetails(type: .fever, occurredAt: moment))

        let action = viewModel.healthConfirmed(HealthDetailsInput(type: .fever, temperatureText: "38,2"))

        #expect(action == .save(RecordDraft(type: .fever, occurredAt: moment, temperatureC: 38.2)))
        #expect(viewModel.sheet == nil)
    }

    @Test func invalidHealthDetailsKeepTheSheetOpen() {
        let viewModel = HomeViewModel()
        viewModel.healthTypePicked(.medicine)
        _ = viewModel.timePicked(moment)

        #expect(viewModel.healthConfirmed(HealthDetailsInput(type: .medicine, noteText: " ")) == nil)
        #expect(viewModel.sheet == .healthDetails(type: .medicine, occurredAt: moment))
    }

    @Test func sleepStartsFromTheTimePicker() {
        let viewModel = HomeViewModel()
        viewModel.cardTapped(.sleep, isSleeping: false)

        #expect(viewModel.sheet == .time(.sleep))
        #expect(viewModel.timePicked(moment) == .startSleep(at: moment))
        #expect(viewModel.sheet == nil)
        #expect(viewModel.toast == nil)
    }

    @Test func tappingTheSleepCardWhileSleepingOffersToStop() {
        let viewModel = HomeViewModel()
        viewModel.cardTapped(.sleep, isSleeping: true)

        #expect(viewModel.sheet == .stopSleep)
        #expect(viewModel.stopSleepConfirmed(at: moment) == .finishSleep(at: moment))
        #expect(viewModel.sheet == nil)
    }

    @Test func dismissingClosesTheSheetWithoutSaving() {
        let viewModel = HomeViewModel()
        viewModel.cardTapped(.poop, isSleeping: false)

        viewModel.dismiss()

        #expect(viewModel.sheet == nil)
        #expect(viewModel.toast == nil)
    }

    @Test func stepsOutOfOrderDoNothing() {
        let viewModel = HomeViewModel()

        #expect(viewModel.timePicked(moment) == nil)
        #expect(viewModel.feedConfirmed(FeedDetailsInput(subtypes: [.breastfeeding])) == nil)
        #expect(viewModel.healthConfirmed(HealthDetailsInput(type: .fever, temperatureText: "38")) == nil)
        #expect(viewModel.stopSleepConfirmed() == nil)
        #expect(viewModel.sheet == nil)
    }

    @Test func eachSavedToastHasItsOwnIdentity() {
        let viewModel = HomeViewModel()
        viewModel.cardTapped(.poop, isSleeping: false)
        _ = viewModel.timePicked(moment)
        let first = viewModel.toast

        viewModel.cardTapped(.poop, isSleeping: false)
        _ = viewModel.timePicked(moment)

        #expect(viewModel.toast != first)
        viewModel.clearToast()
        #expect(viewModel.toast == nil)
    }
}

@MainActor
struct TimeSelectionTests {
    private var now: Date { date(2026, 3, 10, 14, 0) }

    @Test func quickSelectionSubtractsMinutes() {
        #expect(TimeSelection.quick(minutesAgo: 0).resolved(now: now, calendar: calendar) == now)
        #expect(TimeSelection.quick(minutesAgo: 30).resolved(now: now, calendar: calendar) == date(2026, 3, 10, 13, 30))
    }

    @Test func customSelectionUsesTodayWithThePickedTime() {
        let picked = date(2000, 1, 1, 9, 30)

        #expect(TimeSelection.custom(picked).resolved(now: now, calendar: calendar) == date(2026, 3, 10, 9, 30))
    }

    @Test func customTimeLaterThanNowMeansYesterday() {
        let picked = date(2000, 1, 1, 23, 0)

        #expect(TimeSelection.custom(picked).resolved(now: now, calendar: calendar) == date(2026, 3, 9, 23, 0))
    }
}

@MainActor
struct BabyInputTests {
    @Test func blankNameCannotBeSaved() {
        #expect(!BabyInput().canSave)
        #expect(BabyInput(name: "   ").makeBaby() == nil)
    }

    @Test func nameIsTrimmed() {
        #expect(BabyInput(name: "  Ada ").makeBaby()?.name == "Ada")
    }

    @Test func birthDateIsOnlyKeptWhenEnabled() {
        let birth = date(2026, 1, 5)

        #expect(BabyInput(name: "Ada", hasBirthDate: false, birthDate: birth).makeBaby()?.birthDate == nil)
        #expect(BabyInput(name: "Ada", hasBirthDate: true, birthDate: birth).makeBaby()?.birthDate == birth)
    }

    @Test func genderIsOptional() {
        #expect(BabyInput(name: "Ada").makeBaby()?.gender == nil)
        #expect(BabyInput(name: "Ada", gender: .female).makeBaby()?.gender == .female)
    }
}

@MainActor
struct RecordFilterToggleTests {
    @Test func togglingAddsAndRemovesTypes() {
        var filter = RecordFilter()

        filter.toggleType(.feed)
        #expect(filter.types == [.feed])

        filter.toggleType(.poop)
        #expect(filter.types == [.feed, .poop])

        filter.toggleType(.feed)
        #expect(filter.types == [.poop])
    }

    @Test func selectingTheLastRemainingTypeClearsTheSelection() {
        var filter = RecordFilter(types: Set(RecordType.allCases).subtracting([.vitamin]))

        filter.toggleType(.vitamin)

        #expect(filter.types.isEmpty)
    }
}

@MainActor
struct RecordPresentationTests {
    private let moment = date(2026, 3, 10, 9, 0)

    @Test func detailDependsOnTheRecordType() {
        let sleep = BabyRecord(type: .sleep, occurredAt: moment, endedAt: date(2026, 3, 10, 10, 30), durationMinutes: 90)
        let feed = BabyRecord(type: .feed, occurredAt: moment, feedSubtypes: [.breastfeeding], amountMl: 80)
        let fever = BabyRecord(type: .fever, occurredAt: moment, temperatureC: 38.5)
        let medicine = BabyRecord(type: .medicine, occurredAt: moment, note: "Paracetamol")

        #expect(RecordDetail(sleep) == .sleep(minutes: 90, endedAt: date(2026, 3, 10, 10, 30)))
        #expect(RecordDetail(feed) == .feed(subtypes: [.breastfeeding], amountMl: 80))
        #expect(RecordDetail(fever) == .fever(38.5))
        #expect(RecordDetail(medicine) == .note("Paracetamol"))
    }

    @Test func recordsWithoutExtraInformationHaveNoDetail() {
        #expect(RecordDetail(BabyRecord(type: .poop, occurredAt: moment)) == nil)
        #expect(RecordDetail(BabyRecord(type: .feed, occurredAt: moment)) == nil)
        #expect(RecordDetail(BabyRecord(type: .vitamin, occurredAt: moment, note: "")) == nil)
        #expect(RecordDetail(BabyRecord(type: .sleep, occurredAt: moment)) == nil)
    }

    @Test func feedBreakdownCountsSubtypesInFixedOrder() {
        let records = [
            BabyRecord(type: .feed, occurredAt: moment, feedSubtypes: [.extraFormula]),
            BabyRecord(type: .feed, occurredAt: moment, feedSubtypes: [.breastfeeding, .extraFormula]),
            BabyRecord(type: .feed, occurredAt: moment, feedSubtypes: [.breastfeeding]),
            BabyRecord(type: .feed, occurredAt: moment),
        ]

        let breakdown = FeedBreakdown(records: records)

        #expect(breakdown.entries == [
            FeedBreakdown.Entry(subtype: .breastfeeding, count: 2),
            FeedBreakdown.Entry(subtype: .extraFormula, count: 2),
        ])
        #expect(breakdown.untyped == 1)
    }

    @Test func daySummaryDependsOnTheActiveFilter() {
        let records = [
            BabyRecord(type: .feed, occurredAt: moment, feedSubtypes: [.breastfeeding]),
            BabyRecord(type: .poop, occurredAt: moment),
        ]

        #expect(DaySummary(records: records, filter: RecordFilter(period: .all)) == .none)
        #expect(DaySummary(records: records, filter: RecordFilter(types: [.feed, .poop], period: .all)) == .count(2))
        #expect(DaySummary(records: records, filter: RecordFilter(types: [.feed], period: .all)) == .feedBreakdown(FeedBreakdown(records: records)))
    }
}

@MainActor
struct RecordEditInputTests {
    private let moment = date(2026, 3, 10, 9, 0)

    @Test func formStartsEqualToTheRecordAndIsNotDirty() {
        let record = BabyRecord(type: .feed, occurredAt: moment, feedSubtypes: [.breastfeeding], amountMl: 90)

        let input = RecordEditInput(record)

        #expect(input.feed.subtypes == [.breastfeeding])
        #expect(input.feed.amountText == "90")
        #expect(input == RecordEditInput(record))
    }

    @Test func changingAFieldMakesTheFormDirty() {
        let record = BabyRecord(type: .fever, occurredAt: moment, temperatureC: 38.5)
        var input = RecordEditInput(record)

        input.health.temperatureText = "39"

        #expect(input != RecordEditInput(record))
    }

    @Test func feedNeedsASubtypeAndFeverNeedsATemperature() {
        var feed = RecordEditInput(BabyRecord(type: .feed, occurredAt: moment, feedSubtypes: [.breastfeeding]))
        feed.feed.toggle(.breastfeeding)
        #expect(!feed.detailsAreValid)

        var fever = RecordEditInput(BabyRecord(type: .fever, occurredAt: moment, temperatureC: 38))
        fever.health.temperatureText = ""
        #expect(!fever.detailsAreValid)

        #expect(RecordEditInput(BabyRecord(type: .poop, occurredAt: moment)).detailsAreValid)
    }

    @Test func applyWritesTheFeedFields() {
        let record = BabyRecord(type: .feed, occurredAt: moment, feedSubtypes: [.breastfeeding], amountMl: 90)
        var input = RecordEditInput(record)
        input.occurredAt = date(2026, 3, 10, 10, 15)
        input.feed.toggle(.extraFormula)
        input.feed.amountText = "120"

        input.apply(to: record)

        #expect(record.occurredAt == date(2026, 3, 10, 10, 15))
        #expect(record.feedSubtypes == [.breastfeeding, .extraFormula])
        #expect(record.amountMl == 120)
    }

    @Test func applyWritesTheFeverTemperatureOrTheNote() {
        let fever = BabyRecord(type: .fever, occurredAt: moment, temperatureC: 38)
        var feverInput = RecordEditInput(fever)
        feverInput.health.temperatureText = "38,6"
        feverInput.apply(to: fever)
        #expect(fever.temperatureC == 38.6)

        let medicine = BabyRecord(type: .medicine, occurredAt: moment, note: "A")
        var medicineInput = RecordEditInput(medicine)
        medicineInput.health.noteText = "  B 5ml "
        medicineInput.apply(to: medicine)
        #expect(medicine.note == "B 5ml")
    }

    @Test func editingASleepOnlyMovesItsStartTime() {
        let sleep = BabyRecord(type: .sleep, occurredAt: moment, endedAt: date(2026, 3, 10, 10, 30), durationMinutes: 90)
        var input = RecordEditInput(sleep)
        input.occurredAt = date(2026, 3, 10, 8, 30)

        input.apply(to: sleep)

        #expect(sleep.occurredAt == date(2026, 3, 10, 8, 30))
        #expect(sleep.durationMinutes == 90)
        #expect(sleep.endedAt == date(2026, 3, 10, 10, 30))
    }
}

@MainActor
struct RecordsEmptyStateTests {
    @Test func noRecordsAtAllIsDifferentFromNoMatches() {
        #expect(RecordsEmptyState(totalCount: 0, filteredCount: 0) == .noRecords)
        #expect(RecordsEmptyState(totalCount: 5, filteredCount: 0) == .noMatches)
    }

    @Test func nothingIsEmptyWhenThereIsSomethingToShow() {
        #expect(RecordsEmptyState(totalCount: 5, filteredCount: 2) == nil)
    }
}

@MainActor
struct SleepNotificationTests {
    private let babyID = UUID()

    @Test func contentCarriesTheBabyAndAMarker() {
        let content = SleepNotification.content(babyID: babyID, startedAt: date(2026, 3, 10, 1, 0))

        #expect(content.userInfo["type"] == "sleep")
        #expect(content.userInfo["babyID"] == babyID.uuidString)
        #expect(!content.title.isEmpty)
        #expect(content.body.contains(date(2026, 3, 10, 1, 0).formatted(date: .omitted, time: .shortened)))
    }

    @Test func tappingTheNotificationOpensTheStopSleepScreen() {
        let userInfo: [AnyHashable: Any] = ["type": "sleep", "babyID": babyID.uuidString]

        #expect(SleepNotification.response(actionID: UNNotificationDefaultActionIdentifier, userInfo: userInfo) == .openStopSleep)
    }

    @Test func theStopButtonCarriesTheBabyId() {
        let userInfo: [AnyHashable: Any] = ["type": "sleep", "babyID": babyID.uuidString]

        #expect(SleepNotification.response(actionID: SleepNotification.stopActionID, userInfo: userInfo) == .stopSleep(babyID: babyID))
    }

    @Test func otherNotificationsAndBrokenDataAreIgnored() {
        #expect(SleepNotification.response(actionID: UNNotificationDefaultActionIdentifier, userInfo: [:]) == nil)
        #expect(SleepNotification.response(actionID: UNNotificationDefaultActionIdentifier, userInfo: ["type": "other"]) == nil)
        #expect(SleepNotification.response(actionID: SleepNotification.stopActionID, userInfo: ["type": "sleep"]) == nil)
        #expect(SleepNotification.response(actionID: SleepNotification.stopActionID, userInfo: ["type": "sleep", "babyID": "nope"]) == nil)
        #expect(SleepNotification.response(actionID: "unknown", userInfo: ["type": "sleep"]) == nil)
    }
}

private final class FakeNotificationCenter: NotificationCentering {
    var status: UNAuthorizationStatus = .notDetermined
    var grantsPermission = true
    var requestCount = 0
    var added: [UNNotificationRequest] = []
    var removed: [[String]] = []

    func authorizationStatus() async -> UNAuthorizationStatus { status }

    func requestAuthorization() async throws -> Bool {
        requestCount += 1
        return grantsPermission
    }

    func add(_ request: UNNotificationRequest) async throws {
        added.append(request)
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        removed.append(identifiers)
    }
}

@MainActor
struct SleepNotificationServiceTests {
    private let babyID = UUID()

    @Test(arguments: [
        (UNAuthorizationStatus.notDetermined, NotificationPermission.notDetermined),
        (.authorized, .allowed),
        (.provisional, .allowed),
        (.denied, .denied),
    ])
    func permissionMapsTheSystemStatus(status: UNAuthorizationStatus, expected: NotificationPermission) async {
        let center = FakeNotificationCenter()
        center.status = status

        #expect(await SleepNotificationService(center: center).permission() == expected)
    }

    @Test func allowedNotificationsAreShownWithTheStopButtonCategory() async {
        let center = FakeNotificationCenter()
        center.status = .authorized

        let id = await SleepNotificationService(center: center).notifySleepStarted(babyID: babyID, startedAt: date(2026, 3, 10, 1, 0))

        #expect(id != nil)
        #expect(center.added.count == 1)
        #expect(center.added.first?.identifier == id)
        #expect(center.added.first?.content.categoryIdentifier == SleepNotification.categoryID)
        #expect(center.added.first?.content.userInfo["babyID"] as? String == babyID.uuidString)
        #expect(center.added.first?.trigger == nil)
    }

    @Test(arguments: [UNAuthorizationStatus.notDetermined, .denied])
    func nothingIsShownWithoutPermission(status: UNAuthorizationStatus) async {
        let center = FakeNotificationCenter()
        center.status = status

        let id = await SleepNotificationService(center: center).notifySleepStarted(babyID: babyID, startedAt: .now)

        #expect(id == nil)
        #expect(center.added.isEmpty)
    }

    @Test func requestingPermissionReturnsTheAnswer() async {
        let center = FakeNotificationCenter()
        center.grantsPermission = false

        #expect(await SleepNotificationService(center: center).requestPermission() == false)
        #expect(center.requestCount == 1)
    }

    @Test func dismissingRemovesTheDeliveredNotification() {
        let center = FakeNotificationCenter()
        let service = SleepNotificationService(center: center)

        service.dismiss("abc")
        service.dismiss(nil)

        #expect(center.removed == [["abc"]])
    }
}

@MainActor
struct FinishSleepInTheBackgroundTests {
    @Test func finishingSavesTheRecordAndClearsTheSleep() async throws {
        let container = try makeContainer()
        let baby = Baby(name: "Ada")
        baby.activeSleep = ActiveSleep(startedAt: date(2026, 3, 10, 1, 0), notificationID: nil)
        container.mainContext.insert(baby)
        try container.mainContext.save()

        let value = try await RecordService(modelContainer: container)
            .finishSleep(babyID: baby.id, endedAt: date(2026, 3, 10, 2, 30))

        #expect(value?.durationMinutes == 90)
        let stored = try ModelContext(container).fetch(FetchDescriptor<Baby>())
        #expect(stored.first?.activeSleep == nil)
        #expect(stored.first?.records.count == 1)
    }

    @Test func nothingHappensWithoutARunningSleep() async throws {
        let container = try makeContainer()
        let baby = Baby(name: "Ada")
        container.mainContext.insert(baby)
        try container.mainContext.save()

        let value = try await RecordService(modelContainer: container).finishSleep(babyID: baby.id)

        #expect(value == nil)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<BabyRecord>()) == 0)
    }

    @Test func unknownBabyThrows() async throws {
        let container = try makeContainer()

        await #expect(throws: RecordServiceError.babyNotFound) {
            try await RecordService(modelContainer: container).finishSleep(babyID: UUID())
        }
    }
}

@MainActor
struct SleepNotificationCategoryTests {
    @Test func categoryHasABackgroundStopButton() {
        let category = SleepNotification.makeCategory()

        #expect(category.identifier == SleepNotification.categoryID)
        #expect(category.actions.map(\.identifier) == [SleepNotification.stopActionID])
        #expect(category.actions.first?.options.contains(.foreground) == false)
    }
}
