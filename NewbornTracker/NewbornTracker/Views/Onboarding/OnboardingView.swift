import SwiftData
import SwiftUI

private struct IntroPage {
    let symbol: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey
}

private let introPages = [
    IntroPage(
        symbol: "heart.fill",
        title: "Tracking made easy",
        message: "Log poop, pee, feeds, and sleep in one tap. Fever, medicine, and vitamins too."
    ),
    IntroPage(
        symbol: "sparkles",
        title: "See development in one place",
        message: "The vaccine schedule, growth chart, and milestone notes all live in the Growth tab."
    ),
    IntroPage(
        symbol: "lock.fill",
        title: "Private on your device",
        message: "Everything is stored on your phone. No account, no sign-up."
    ),
]

/// The first screen a new user sees: three intro pages, then the baby's name.
struct OnboardingView: View {
    let onFinish: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(ActiveBabyStore.self) private var activeBabyStore
    @State private var flow = OnboardingFlow()
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if flow.isIntro {
                    introContent(introPages[flow.step])
                } else {
                    nameContent
                }
            }
            .id(flow.step)
            .transition(.opacity.combined(with: .offset(y: 12)))
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            pageDots
                .padding(.bottom, 32)

            controls
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 24)
        .background(Color.appSurface.ignoresSafeArea())
        .animation(.easeOut(duration: 0.22), value: flow.step)
        .onChange(of: flow.isIntro) { _, isIntro in
            isNameFocused = !isIntro
        }
    }

    private func introContent(_ page: IntroPage) -> some View {
        VStack(spacing: 12) {
            badge(symbol: page.symbol)
            Text(page.title)
                .scaledFont(size: 24, weight: .heavy)
                .foregroundStyle(Color.appInk)
                .multilineTextAlignment(.center)
            Text(page.message)
                .scaledFont(size: 16)
                .foregroundStyle(Color.appMuted)
                .multilineTextAlignment(.center)
        }
    }

    private var nameContent: some View {
        VStack(spacing: 12) {
            badge(symbol: "person.fill")
            Text("What's your baby's name?")
                .scaledFont(size: 24, weight: .heavy)
                .foregroundStyle(Color.appInk)
                .multilineTextAlignment(.center)
            Text("You can add the birth date and gender later in Settings.")
                .scaledFont(size: 16)
                .foregroundStyle(Color.appMuted)
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)
            TextField("Baby's name", text: $flow.baby.name)
                .focused($isNameFocused)
                .submitLabel(.done)
                .onSubmit(finish)
                .multilineTextAlignment(.center)
                .scaledFont(size: 16, weight: .semibold)
                .foregroundStyle(Color.appInk)
                .frame(minHeight: 52)
                .background(Color.appSurfaceElevated, in: .capsule)
                .onChange(of: flow.baby.name) { _, newValue in
                    flow.baby.name = String(newValue.prefix(30))
                }
        }
    }

    private func badge(symbol: String) -> some View {
        Image(systemName: symbol)
            .scaledFont(size: 34)
            .foregroundStyle(Color.appHighlight)
            .frame(width: 80, height: 80)
            .background(Color.appHighlight.opacity(0.1), in: .circle)
            .padding(.bottom, 12)
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<flow.stepCount, id: \.self) { index in
                Capsule()
                    .fill(index == flow.step ? Color.appHighlight : Color.appBorder)
                    .frame(width: index == flow.step ? 24 : 6, height: 6)
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var controls: some View {
        if flow.isIntro {
            HStack {
                Button("Skip") { flow.skip() }
                    .scaledFont(size: 16, weight: .semibold)
                    .foregroundStyle(Color.appMuted)
                    .padding(.vertical, 12)
                Spacer()
                PillButton(title: "Next") { flow.next() }
                    .frame(width: 140)
            }
        } else {
            PillButton(title: "Get started", action: finish)
                .disabled(!flow.canFinish)
        }
    }

    private func finish() {
        guard let baby = flow.makeBaby() else { return }
        context.insert(baby)
        activeBabyStore.select(baby)
        onFinish()
    }
}
