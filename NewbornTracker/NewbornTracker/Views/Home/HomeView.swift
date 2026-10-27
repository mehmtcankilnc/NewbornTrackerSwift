import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \Baby.createdAt) private var babies: [Baby]
    @Environment(ActiveBabyStore.self) private var activeBabyStore
    @State private var isAddingBaby = false

    var body: some View {
        Group {
            if let baby = activeBabyStore.activeBaby(in: babies) {
                HomeContent(baby: baby)
            } else {
                ContentUnavailableView {
                    Label("Welcome", systemImage: "heart")
                } description: {
                    Text("Add your baby to start logging.")
                } actions: {
                    PillButton(title: "Add your baby") { isAddingBaby = true }
                        .padding(.horizontal, 40)
                }
                .foregroundStyle(Color.appInk)
            }
        }
        .background(Color.appSurface.ignoresSafeArea())
        .sheet(isPresented: $isAddingBaby) { AddBabySheet() }
        .task {
            if babies.isEmpty { isAddingBaby = true }
        }
    }
}

private struct HomeContent: View {
    let baby: Baby

    @Environment(\.modelContext) private var context
    @Query private var records: [BabyRecord]
    @State private var viewModel = HomeViewModel()

    init(baby: Baby) {
        self.baby = baby
        let babyID = baby.id
        _records = Query(filter: #Predicate<BabyRecord> { $0.baby?.id == babyID })
    }

    var body: some View {
        let summary = HomeSummary(records: records)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.top, 16)

                Text("Hi, \(baby.name)! 👶")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(Color.appInk)
                    .lineLimit(1)
                    .padding(.top, 16)
                Text("Start by adding a record")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appMuted)
                    .padding(.top, 4)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible())], spacing: 12) {
                    ForEach([RecordType.poop, .piss, .feed], id: \.self) { type in
                        StatCard(
                            title: type.title,
                            symbol: type.symbolName,
                            accent: type.accent,
                            value: String(summary.count(for: type)),
                            unit: summary.count(for: type) > 0 ? "times" : nil,
                            subtitle: lastSubtitle(summary.lastTime(for: type))
                        ) {
                            viewModel.cardTapped(type, isSleeping: baby.activeSleep != nil)
                        }
                    }
                    sleepCard(summary)
                }
                .padding(.top, 24)

                Text("Status")
                    .font(.system(size: 12, weight: .semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(Color.appMuted)
                    .padding(.top, 24)
                    .padding(.bottom, 8)

                SecondaryStatRow(
                    title: "Health",
                    symbol: "cross.case",
                    accent: RecordType.medicine.accent,
                    value: String(summary.healthCountToday),
                    subtitle: lastSubtitle(summary.lastHealthTime)
                ) {
                    viewModel.healthCardTapped()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .overlay(alignment: .bottom) { toastView }
        .animation(.easeOut(duration: 0.2), value: viewModel.toast)
        .sensoryFeedback(.success, trigger: viewModel.toast)
        .task(id: viewModel.toast?.id) {
            guard viewModel.toast != nil else { return }
            try? await Task.sleep(for: .seconds(1.5))
            viewModel.clearToast()
        }
        .sheet(item: $viewModel.sheet) { sheet in
            sheetContent(for: sheet)
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "heart.fill")
                .font(.system(size: 13))
            Text("Today, \(Date.now.formatted(.dateTime.day().month(.wide)))")
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundStyle(Color.appHighlight)
        .frame(height: 36)
        .overlay(alignment: .bottom) {
            Line()
                .stroke(Color.appHighlight, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .frame(height: 1)
        }
    }

    private func sleepCard(_ summary: HomeSummary) -> some View {
        TimelineView(.periodic(from: .now, by: 30)) { timeline in
            let sleep = baby.activeSleep
            StatCard(
                title: RecordType.sleep.title,
                symbol: RecordType.sleep.symbolName,
                accent: RecordType.sleep.accent,
                value: sleepValue(sleep: sleep, summary: summary, now: timeline.date),
                subtitle: sleep != nil ? String(localized: "Ongoing") : lastSubtitle(summary.lastTime(for: .sleep)),
                topRight: sleep.map { $0.startedAt.formatted(date: .omitted, time: .shortened) },
                showsDot: sleep != nil
            ) {
                viewModel.cardTapped(.sleep, isSleeping: sleep != nil)
            }
        }
    }

    private func sleepValue(sleep: ActiveSleep?, summary: HomeSummary, now: Date) -> String {
        if let sleep {
            return DurationText.string(minutes: SleepTimer.elapsedMinutes(of: sleep, now: now), style: .compact)
        }
        if summary.sleepMinutes > 0 {
            return DurationText.string(minutes: summary.sleepMinutes, style: .compact)
        }
        return "—"
    }

    private func lastSubtitle(_ time: Date?) -> String {
        guard let time else { return String(localized: "Not yet") }
        return String(localized: "Last: \(time.formatted(date: .omitted, time: .shortened))")
    }

    @ViewBuilder
    private var toastView: some View {
        if let toast = viewModel.toast {
            Text("\(String(localized: toast.type.title)) saved · \(toast.time.formatted(date: .omitted, time: .shortened))")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.appPrimary, in: .capsule)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: HomeViewModel.Sheet) -> some View {
        switch sheet {
        case .time(let type):
            TimePickerSheet(title: type.question) { time in
                perform(viewModel.timePicked(time))
            } onCancel: {
                viewModel.dismiss()
            }
        case .feedDetails:
            FeedDetailsSheet { input in
                perform(viewModel.feedConfirmed(input))
            } onCancel: {
                viewModel.dismiss()
            }
        case .healthPicker:
            HealthTypePickerSheet { type in
                viewModel.healthTypePicked(type)
            }
        case .healthDetails(let type, _):
            HealthDetailsSheet(type: type) { input in
                perform(viewModel.healthConfirmed(input))
            } onCancel: {
                viewModel.dismiss()
            }
        case .stopSleep:
            if let sleep = baby.activeSleep {
                StopSleepSheet(sleep: sleep) { endedAt in
                    perform(viewModel.stopSleepConfirmed(at: endedAt))
                } onCancel: {
                    viewModel.dismiss()
                }
            }
        }
    }

    private func perform(_ action: HomeViewModel.Action?) {
        guard let action else { return }

        switch action {
        case .save(let draft):
            context.insertRecord(draft, for: baby)
        case .startSleep(let startedAt):
            baby.activeSleep = ActiveSleep(startedAt: startedAt, notificationID: nil)
        case .finishSleep(let endedAt):
            context.finishSleep(of: baby, endedAt: endedAt)
        }
    }
}

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}
