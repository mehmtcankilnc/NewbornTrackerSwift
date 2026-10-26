import Foundation
import Testing
import SwiftData
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
