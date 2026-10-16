import SwiftUI

/// "Ranking: 12 / 1,204" or "Score: 88 / 100", coloured by the movie's score.
struct ScoreCard: View {
    let label: String
    let value: String
    let total: String
    let score: Int

    var body: some View {
        let color = Color.score(score)
        VStack(spacing: 4) {
            Text(label)
                .font(.headline)
                .foregroundStyle(.appAccent)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Rectangle()
                .fill(color)
                .frame(width: 56, height: 2)
            Text(total)
                .font(.title2.bold())
                .foregroundStyle(color)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value) of \(total)")
    }
}
