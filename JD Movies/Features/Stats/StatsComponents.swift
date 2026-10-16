import Charts
import SwiftUI

/// A big number with a caption, optionally linking to a filtered grid.
struct HeroTile: View {
    let value: String
    let label: String
    var color: Color = .appAccent
    var route: Route?

    var body: some View {
        if let route {
            NavigationLink(value: route) { tile }
                .buttonStyle(.plain)
        } else {
            tile
        }
    }

    private var tile: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title.bold())
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(label)
                .font(.footnote)
                .foregroundStyle(.appLight)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 84)
        .padding(8)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Movies per 5-point score bucket, coloured along the score gradient.
struct ScoreHistogramChart: View {
    let distribution: [Int]

    var body: some View {
        let buckets = ScoreBuckets.histogram(distribution)
        let labels = buckets.map { String($0.bucket.range.lowerBound) }
        Chart(buckets) { item in
            BarMark(x: .value("Score", String(item.bucket.range.lowerBound)),
                    y: .value("Movies", item.count))
                .foregroundStyle(Color.score(item.bucket.midpoint))
                .cornerRadius(2)
        }
        .chartXScale(domain: labels)
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: labels.filter { (Int($0) ?? 0) % 20 == 0 }) { _ in
                AxisValueLabel()
                    .foregroundStyle(Color.appLight)
            }
        }
        .frame(height: 160)
        .accessibilityLabel("Score distribution")
    }
}

/// One bar per group (decade, genre): height is the count, colour is the average score.
struct CountBarsChart: View {
    let data: [GroupStat]
    var barWidth: CGFloat = 44

    private var averages: [String: Double] {
        Dictionary(data.map { ($0.label, $0.average) }, uniquingKeysWith: { first, _ in first })
    }

    var body: some View {
        let averages = self.averages
        VStack(spacing: 6) {
            Chart(data) { item in
                BarMark(x: .value("Group", item.label),
                        y: .value("Movies", item.count),
                        width: .fixed(barWidth * 0.7))
                    .foregroundStyle(Color.score(item.average))
                    .cornerRadius(3)
                    .annotation(position: .top, spacing: 2) {
                        Text("\(item.count)")
                            .font(.caption2)
                            .foregroundStyle(.appLight)
                    }
            }
            .chartXScale(domain: data.map(\.label))
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel(centered: true) {
                        if let label = value.as(String.self) {
                            VStack(spacing: 2) {
                                Text(label)
                                    .font(.caption2)
                                    .foregroundStyle(.appLight)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(width: barWidth)
                                if let average = averages[label] {
                                    Text(average, format: .number.precision(.fractionLength(2)))
                                        .font(.caption2.bold())
                                        .foregroundStyle(Color.score(average))
                                }
                            }
                        }
                    }
                }
            }
            .frame(width: CGFloat(data.count) * (barWidth + 8), height: 180)
            Text("Coloured number = average score")
                .font(.caption2)
                .foregroundStyle(.appMuted)
        }
    }
}

/// Highest / lowest / most watched lists behind a segmented control.
struct LeaderboardSection: View {
    enum Board: String, CaseIterable, Identifiable {
        case best = "Highest Average"
        case worst = "Lowest Average"
        case mostWatched = "Most Watched"

        var id: String { rawValue }
    }

    let title: String
    let boards: Leaderboards
    var mostWatchedTitle = "Most Watched"
    let routeFor: (PersonStat) -> Route

    @State private var board: Board = .best

    private var people: [PersonStat] {
        switch board {
        case .best: boards.best
        case .worst: boards.worst
        case .mostWatched: boards.mostWatched
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title)
            Picker("Board", selection: $board) {
                ForEach(Board.allCases) { board in
                    Text(board == .mostWatched ? mostWatchedTitle : board.rawValue).tag(board)
                }
            }
            .pickerStyle(.segmented)
            VStack(alignment: .leading, spacing: 8) {
                if people.isEmpty {
                    Text("Not enough movies yet.")
                        .foregroundStyle(.appMuted)
                }
                ForEach(Array(people.enumerated()), id: \.element.id) { index, person in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.footnote)
                            .foregroundStyle(.appMuted)
                            .frame(width: 24, alignment: .trailing)
                        NavigationLink(value: routeFor(person)) {
                            Text(person.name)
                                .underline()
                                .foregroundStyle(.appLight)
                                .lineLimit(1)
                        }
                        .buttonStyle(.plain)
                        Spacer(minLength: 4)
                        Text(person.average, format: .number.precision(.fractionLength(2)))
                            .bold()
                            .foregroundStyle(Color.score(person.average))
                        Text("(\(person.count))")
                            .font(.footnote)
                            .foregroundStyle(.appMuted)
                    }
                }
            }
            .card()
        }
    }
}

/// Where my scores and the critics' disagree the most, per review site.
struct CriticsSection: View {
    let critics: [CriticSite]
    @State private var selectedSite: String

    init(critics: [CriticSite]) {
        self.critics = critics
        _selectedSite = State(initialValue: critics.first?.site ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle("Critics Disagreement")
            Picker("Site", selection: $selectedSite) {
                ForEach(critics) { site in
                    Text(site.site).tag(site.site)
                }
            }
            .pickerStyle(.segmented)
            if let site = critics.first(where: { $0.site == selectedSite }) {
                gapList("I Liked More", site.higher)
                gapList("Critics Liked More", site.lower)
            }
        }
    }

    private func gapList(_ title: String, _ gaps: [CriticGap]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.appAccent)
            ForEach(Array(gaps.enumerated()), id: \.element.id) { index, gap in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(index + 1).")
                        .font(.footnote)
                        .foregroundStyle(.appMuted)
                        .frame(width: 24, alignment: .trailing)
                    NavigationLink(value: Route.movie(gap.tmdbID)) {
                        Text(gap.title)
                            .underline()
                            .foregroundStyle(.appLight)
                            .lineLimit(1)
                    }
                    .buttonStyle(.plain)
                    Spacer(minLength: 4)
                    Text("\(gap.mine)")
                        .bold()
                        .foregroundStyle(Color.score(gap.mine))
                    Text("vs \(gap.theirs)")
                        .font(.footnote)
                        .foregroundStyle(.appMuted)
                }
            }
        }
        .card()
    }
}

/// The top-scored movie of every year, newest first.
struct BestOfYearRow: View {
    let items: [YearBest]

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 12) {
                ForEach(items) { item in
                    VStack(spacing: 6) {
                        Text(String(item.year))
                            .font(.headline)
                            .foregroundStyle(.appAccent)
                        PosterLink(movie: item.movie)
                    }
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
    }
}
