import Foundation

/// The first-launch flow: three intro pages, then the baby's name.
struct OnboardingFlow: Equatable {
    static let introPageCount = 3

    private(set) var step = 0
    var baby = BabyInput()

    var stepCount: Int { Self.introPageCount + 1 }
    var isIntro: Bool { step < Self.introPageCount }
    var canFinish: Bool { !isIntro && baby.canSave }

    mutating func next() {
        step = min(step + 1, stepCount - 1)
    }

    /// Jumps over the intro pages to the name step.
    mutating func skip() {
        step = stepCount - 1
    }

    /// The baby to save, only from the last step and with a name.
    func makeBaby() -> Baby? {
        canFinish ? baby.makeBaby() : nil
    }
}
