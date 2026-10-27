# Newborn Tracker (SwiftUI)

A newborn care tracker for iOS, rebuilt from a React Native app in SwiftUI. Log poop, pee, feeds and sleep in one tap, review the history with filters and a chart, follow growth against WHO percentile curves, tick off vaccines and keep a milestone journal with photos. A running sleep shows as a Live Activity and the home screen widget logs records without opening the app.

This project was written as a hands-on way to learn Swift and iOS architecture, so the code favors clarity over cleverness and the architecture is documented below.

## Features

- **Quick entry:** poop, pee, feed (with type and amount), sleep timer, and fever, medicine and vitamin records, each with a "when did it happen" picker
- **Records:** day-grouped history, filters by type and period (including a custom range), list or bar chart view (Swift Charts), edit and delete
- **Sleep timer:** notification with a "Stop sleep" action, plus a Live Activity with a lock screen card and Dynamic Island layouts that has its own Stop button
- **Growth:** weight, height and head circumference measurements plotted against the WHO 2006 percentile curves (P3 to P97)
- **Vaccines and milestones:** a built-in checklist plus your own entries, milestone notes and photos picked with `PhotosPicker`
- **Home screen widget:** today's counts, tap a tile to add a record (App Intents)
- **Multiple babies**, onboarding, light, dark or system appearance
- **English and Turkish** through a String Catalog

## Tech

| | |
|---|---|
| UI | SwiftUI, Swift Charts |
| State | Observation framework (`@Observable`), `@State`, `@Environment`, `@Bindable`, `@AppStorage` |
| Persistence | SwiftData, stored in an App Group so the app and the widget share one database |
| Concurrency | `async`/`await`, `@ModelActor` for background writes |
| System features | ActivityKit (Live Activity), WidgetKit, App Intents, UserNotifications, PhotosUI |
| Localization | String Catalog (`Localizable.xcstrings`), English and Turkish |
| Tests | Swift Testing, 180+ tests |
| Dependencies | None, only Apple frameworks |

Requires Xcode 27 and iOS 27. Open `NewbornTracker/NewbornTracker.xcodeproj` and run the `NewbornTracker` scheme. The Live Activity and the widget need the App Group `group.com.mehmtcan.NewbornTracker`, which Xcode registers for your own team when you set it under Signing & Capabilities.

## Architecture

The app follows **MVVM** with small, pure logic types. Dependencies point one way: views know view models and models, logic types know models, models know nothing.

```
View  ──►  ViewModel / Input  ──►  Model (SwiftData)
 │                │
 └────►  Services (pure logic, background actors)
```

| Layer | Responsibility | Examples |
|---|---|---|
| **Model** | `@Model` classes and plain value types. No UI. | `Baby`, `BabyRecord`, `GrowthMeasurement`, `RecordFilter`, `Period`, `RecordValue` |
| **Input** | A form's state as an `Equatable` struct. The view edits it, a method turns it into a model on Save. | `BabyInput`, `GrowthEntryInput`, `MilestoneInput`, `RecordEditInput` |
| **ViewModel** | State and decisions of the Home screen as an enum state machine. It returns an action and the view performs the database write. | `HomeViewModel` |
| **Service** | Pure functions and I/O behind small types. Easy to test without a screen. | `DayGrouper`, `ChartData`, `WhoPercentiles`, `GrowthSeries`, `PhotoStorage`, `RecordService` |
| **Store** | App-wide state shared across screens. | `ActiveBabyStore`, `AppRouter` |
| **View** | Describes the screen from state. Small reusable pieces live in `Components/`. | `HomeView`, `RecordsView`, `GrowthView`, `SettingsView` |

### Decisions worth knowing

- **Derived state is computed, not stored.** Counts, durations, "today" summaries and percentile values are calculated from the records, so they cannot drift out of sync.
- **Illegal states are unrepresentable.** A custom date range is `Period.custom(from:to:)`, not two optional dates, and each sheet is one case of an enum instead of several booleans.
- **`now` and `calendar` are default parameters.** Date logic takes them as arguments, so tests pin the clock and the time zone.
- **Writes off the main thread go through `@ModelActor`.** `RecordService` owns its own `ModelContext`, and Sendable value snapshots such as `RecordValue` cross the actor boundary instead of models.
- **Photos are stored by file name, never by path.** The full path of the app folder changes when the app is updated, so the database keeps only the file name. `MilestoneInput` also tracks which files are no longer needed, so no photo is left behind on disk.
- **The widget draws a snapshot, not the database.** `WidgetDataService` builds a `WidgetSnapshot` of plain values, and the widget never touches SwiftData directly.
- **Live Activity timer is drawn by the system.** `Text(timerInterval:)` ticks by itself, so the activity needs no updates while the baby sleeps.
- **System formatters over hand-made strings.** Dates, durations and measurements use `Date.formatted`, `Duration.UnitsFormatStyle` and `Measurement`, so they follow the user's language and region.
- **Notifications and permissions are wrapped.** `SleepNotificationService` talks to a small protocol, so tests use a fake center and never touch the system.

### Data flow example: stopping a sleep from the Live Activity

1. The user taps **Stop sleep** on the lock screen card. It is a `Button(intent: StopSleepIntent)`.
2. As a `LiveActivityIntent`, `StopSleepIntent` runs inside the app process, even if the app was closed.
3. It opens the shared SwiftData container and asks `RecordService.finishSleep` to save the sleep record and clear the running sleep.
4. It dismisses the notification, ends the Live Activity and reloads the widget timelines.
5. The next time the app opens, `HomeView` reads the new record from SwiftData and shows it.

## Project structure

```
NewbornTracker/
├── NewbornTracker/
│   ├── App/                     App entry point, creates the container and the notification delegate
│   ├── Models/                  SwiftData models, value types, form inputs, WHO table, schedules
│   ├── Services/                Pure logic, record service, notifications, photo storage
│   ├── Shared/                  Files compiled into both the app and the widget extension
│   ├── Stores/                  ActiveBabyStore, AppRouter
│   ├── ViewModels/              HomeViewModel
│   ├── Views/                   Home, Records, Growth, Settings, Onboarding, Components
│   ├── Theme/                   Colors (light and dark), record type styles
│   ├── Localizable.xcstrings    English and Turkish
│   └── Assets.xcassets
├── NewbornTrackerWidgets/       Widget extension: home screen widget and Live Activity
├── NewbornTrackerTests/         Unit tests (Swift Testing)
└── NewbornTrackerUITests/
```

## Tests

Run with `⌘U` in Xcode. The suite covers the domain logic (stats, grouping, filters, periods), the SwiftData models and relationships, the record service, form inputs and their validation, the sleep timer and notification logic, chart data, WHO percentile math, checklists, photo storage, settings logic, onboarding and the widget snapshot.

## Phases

The app was built in phases, each ending with tests and a commit. `PLAN.md` holds the plan, the React Native to Swift mapping and what each phase was meant to teach.

## Origin

The original React Native version used Zustand stores, Expo Router, `react-native-svg` charts and AsyncStorage. Roughly, those map to SwiftData with `@Query`, `TabView` and `.sheet`, Swift Charts and an App Group shared database here. The Swift version also fixes a few weak spots of the original: dates are real `Date` values instead of ISO strings, ids are `UUID`s, photos are stored by file name, deleting a baby also removes its photos, and the timer shows as a Live Activity because iOS has no sticky notification.
