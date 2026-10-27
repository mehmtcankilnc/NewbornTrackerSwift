import SwiftUI

struct RecordRow: View {
    let record: BabyRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.type.symbolName)
                .scaledFont(size: 19)
                .foregroundStyle(record.type.accent)
                .frame(width: 44, height: 44)
                .background(record.type.accentBackground, in: .circle)

            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: record.type.title))
                    .scaledFont(size: 16, weight: .semibold)
                    .foregroundStyle(Color.appInk)
                if let detail = detailText {
                    Text(detail)
                        .scaledFont(size: 12)
                        .foregroundStyle(Color.appMuted)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            Text(record.occurredAt.formatted(date: .omitted, time: .shortened))
                .scaledFont(size: 12, weight: .semibold)
                .monospacedDigit()
                .foregroundStyle(Color.appMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .cardSurface(cornerRadius: 16, shadowRadius: 3, shadowY: 1)
        .accessibilityElement(children: .combine)
    }

    private var detailText: String? {
        guard let detail = RecordDetail(record) else { return nil }

        switch detail {
        case .sleep(let minutes, let endedAt):
            let duration = DurationText.string(minutes: minutes)
            guard let endedAt else { return duration }
            return "\(duration) · " + String(localized: "until \(endedAt.formatted(date: .omitted, time: .shortened))")
        case .feed(let subtypes, let amountMl):
            let names = subtypes.map { String(localized: $0.title) }.joined(separator: ", ")
            guard let amountMl else { return names }
            return "\(names) · \(amountMl) ml"
        case .fever(let temperature):
            return "\(temperature.formatted())°C"
        case .note(let note):
            return note
        }
    }
}
