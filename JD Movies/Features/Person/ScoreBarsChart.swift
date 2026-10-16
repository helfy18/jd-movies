import Charts
import SwiftUI

/// How a person's movies spread across score bands.
struct ScoreBarsChart: View {
    let scores: [Int]

    var body: some View {
        let counts = ScoreBuckets.counts(of: scores)
        VStack(alignment: .leading, spacing: 4) {
            Text("Scores Given")
                .font(.subheadline)
                .foregroundStyle(.appAccent)
            Chart(counts) { item in
                BarMark(x: .value("Score", item.bucket.label), y: .value("Movies", item.count))
                    .foregroundStyle(Color.score(item.bucket.midpoint))
                    .cornerRadius(3)
                    .annotation(position: .top, spacing: 2) {
                        if item.count > 0 {
                            Text("\(item.count)")
                                .font(.caption2)
                                .foregroundStyle(.appLight)
                        }
                    }
            }
            .chartXScale(domain: counts.map(\.bucket.label))
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.appLight)
                }
            }
            .frame(height: 110)
        }
    }
}
