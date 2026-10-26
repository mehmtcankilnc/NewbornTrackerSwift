enum FeedSubtype: String, Codable, CaseIterable, Identifiable {
    case breastfeeding
    case extraBreastMilk = "extra_breast_milk"
    case extraFormula = "extra_formula"

    var id: String { rawValue }
}
