import Foundation

/// A labelled bucket (decade, genre) with its movie count and average score.
nonisolated struct GroupStat: Hashable, Sendable, Identifiable {
    let label: String
    let count: Int
    let average: Double
    /// Grid filter the bucket links to, when it has one.
    let query: MovieListQuery?

    var id: String { label }
}

nonisolated struct PersonStat: Hashable, Sendable, Identifiable {
    let name: String
    let count: Int
    let average: Double
    /// Filter value for links when it differs from the display name.
    let filter: String?

    var id: String { name }
    var filterValue: String { filter ?? name }
}

nonisolated struct Leaderboards: Hashable, Sendable {
    let best: [PersonStat]
    let worst: [PersonStat]
    let mostWatched: [PersonStat]
}

nonisolated struct CriticGap: Hashable, Sendable, Identifiable {
    let title: String
    let tmdbID: Int
    let mine: Int
    let theirs: Int

    var id: Int { tmdbID }
}

nonisolated struct CriticSite: Hashable, Sendable, Identifiable {
    let site: String
    /// Movies I scored furthest above the critics.
    let higher: [CriticGap]
    /// Movies the critics scored furthest above me.
    let lower: [CriticGap]

    var id: String { site }
}

nonisolated struct DaniStats: Hashable, Sendable {
    nonisolated struct TopGenre: Hashable, Sendable {
        let label: String
        let rate: Double
    }

    let count: Int
    let averageApproved: Double
    let averageRest: Double
    let topGenre: TopGenre?
}

nonisolated struct YearBest: Hashable, Sendable, Identifiable {
    let year: Int
    let movie: PosterMovie

    var id: Int { year }
}

/// Running count and sum of scores for one key.
private nonisolated struct Tally: Hashable, Sendable {
    var count = 0
    var sum = 0.0

    var average: Double { count == 0 ? 0 : sum / Double(count) }
}

private nonisolated struct Tallies: Sendable {
    private(set) var entries: [String: Tally] = [:]

    mutating func add(_ key: String, score: Int) {
        var tally = entries[key] ?? Tally()
        tally.count += 1
        tally.sum += Double(score)
        entries[key] = tally
    }

    func groupStats() -> [GroupStat] {
        entries.map { GroupStat(label: $0.key, count: $0.value.count, average: $0.value.average, query: nil) }
    }

    func people(minimumCount: Int) -> [PersonStat] {
        entries
            .filter { $0.value.count >= minimumCount }
            .map { PersonStat(name: $0.key, count: $0.value.count, average: $0.value.average, filter: nil) }
    }
}

/// Everything the stats screen shows, aggregated from the full catalogue.
nonisolated struct SiteStats: Hashable, Sendable {
    static let bucketSize = 5
    static let bucketCount = 100 / bucketSize
    static let minDirectorMovies = 3
    static let minActorMovies = 5
    static let topBilling = 10
    static let genreLimit = 20
    static let minSubUniverseMovies = 3
    static let criticGapSize = 10
    static let daniGenreMinimum = 20
    static let leaderboardSize = 10

    let movieCount: Int
    let runtimeDays: Double
    let averageScore: Double
    let medianScore: Double
    let perfectScores: Int
    /// Movie counts per 5-point score bucket; 100 lands in the last bucket.
    let distribution: [Int]
    let decades: [GroupStat]
    let genres: [GroupStat]
    let directors: Leaderboards
    /// Averages count top-billed roles only; counts include every appearance.
    let actors: Leaderboards
    let subUniverses: Leaderboards
    let critics: [CriticSite]
    let dani: DaniStats
    let bestByYear: [YearBest]

    static func build(from catalogue: [Movie]) -> SiteStats {
        var distribution = Array(repeating: 0, count: bucketCount)
        var decades = Tallies()
        var genres = Tallies()
        var directors = Tallies()
        var actors = Tallies()
        var topBilledActors = Tallies()
        var subUniverses = Tallies()
        var subUniverseParents: [String: String] = [:]
        var runtimeMinutes = 0
        var scoreSum = 0

        for movie in catalogue {
            let score = movie.score
            scoreSum += score
            runtimeMinutes += movie.runtime
            let bucket = max(0, min(bucketCount - 1, score / bucketSize))
            distribution[bucket] += 1
            decades.add("\(movie.year / 10 * 10)s", score: score)
            for genre in movie.genres {
                genres.add(genre, score: score)
            }
            if let franchise = movie.franchise {
                subUniverses.add(franchise, score: score)
                if let sub = movie.subUniverse.nonEmpty, let universe = movie.universe.nonEmpty {
                    subUniverseParents[sub] = universe
                }
            }
            for name in movie.directors {
                directors.add(name, score: score)
            }
            for (billing, name) in movie.cast.enumerated() {
                actors.add(name, score: score)
                if billing < topBilling { topBilledActors.add(name, score: score) }
            }
        }

        let decadeStats = decades.groupStats()
            .sorted { $0.label < $1.label }
            .map { stat in
                let start = Int(stat.label.dropLast()) ?? 0
                return GroupStat(label: stat.label, count: stat.count, average: stat.average,
                                 query: .decade(startingAt: start))
            }
        let genreStats = genres.groupStats()
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                if lhs.average != rhs.average { return lhs.average > rhs.average }
                return lhs.label < rhs.label
            }
            .map { GroupStat(label: $0.label, count: $0.count, average: $0.average,
                             query: MovieListQuery(genre: [$0.label])) }

        return SiteStats(
            movieCount: catalogue.count,
            runtimeDays: (Double(runtimeMinutes) / 60 / 24 * 10).rounded() / 10,
            averageScore: catalogue.isEmpty ? 0 : Double(scoreSum) / Double(catalogue.count),
            medianScore: median(catalogue.map(\.score)),
            perfectScores: catalogue.filter { $0.score == 100 }.count,
            distribution: distribution,
            decades: decadeStats,
            genres: capGenres(genreStats),
            directors: leaderboards(average: directors, count: directors, minimumCount: minDirectorMovies),
            actors: leaderboards(average: topBilledActors, count: actors, minimumCount: minActorMovies),
            subUniverses: labelSubUniverses(
                leaderboards(average: subUniverses, count: subUniverses, minimumCount: minSubUniverseMovies),
                parents: subUniverseParents
            ),
            critics: buildCritics(catalogue),
            dani: buildDani(catalogue),
            bestByYear: buildBestByYear(catalogue)
        )
    }

    // MARK: - Pieces

    private static func median(_ scores: [Int]) -> Double {
        guard !scores.isEmpty else { return 0 }
        let sorted = scores.sorted()
        let mid = sorted.count / 2
        if sorted.count % 2 == 1 { return Double(sorted[mid]) }
        return Double(sorted[mid - 1] + sorted[mid]) / 2
    }

    /// Keeps the top genres and folds the long tail into a single "Other" bucket.
    private static func capGenres(_ stats: [GroupStat]) -> [GroupStat] {
        let top = Array(stats.prefix(genreLimit))
        let rest = stats.dropFirst(genreLimit)
        guard !rest.isEmpty else { return top }
        let count = rest.reduce(0) { $0 + $1.count }
        let sum = rest.reduce(0.0) { $0 + $1.average * Double($1.count) }
        return top + [GroupStat(label: "Other", count: count, average: sum / Double(count), query: nil)]
    }

    /// For actors the tallies differ: averages use top-billed roles, counts use all.
    private static func leaderboards(average: Tallies, count: Tallies, minimumCount: Int) -> Leaderboards {
        let byAverage = average.people(minimumCount: minimumCount).sorted { lhs, rhs in
            if lhs.average != rhs.average { return lhs.average > rhs.average }
            if lhs.count != rhs.count { return lhs.count > rhs.count }
            return lhs.name < rhs.name
        }
        let byCount = count.people(minimumCount: minimumCount).sorted { lhs, rhs in
            if lhs.count != rhs.count { return lhs.count > rhs.count }
            if lhs.average != rhs.average { return lhs.average > rhs.average }
            return lhs.name < rhs.name
        }
        return Leaderboards(
            best: Array(byAverage.prefix(leaderboardSize)),
            worst: Array(byAverage.suffix(leaderboardSize).reversed()),
            mostWatched: Array(byCount.prefix(leaderboardSize))
        )
    }

    /// Prefixes a sub-universe with its parent ("Marvel - Spider-Verse") while keeping the raw filter value.
    private static func labelSubUniverses(_ boards: Leaderboards, parents: [String: String]) -> Leaderboards {
        func label(_ person: PersonStat) -> PersonStat {
            let parent = parents[person.name]
            let name = parent.map { $0 != person.name ? "\($0) - \(person.name)" : person.name } ?? person.name
            return PersonStat(name: name, count: person.count, average: person.average, filter: person.name)
        }
        return Leaderboards(best: boards.best.map(label),
                            worst: boards.worst.map(label),
                            mostWatched: boards.mostWatched.map(label))
    }

    /// Parses "7.5/10", "85%" or "70/100" style critic scores onto a 0-100 scale.
    static func criticScore(_ value: String, suffix: String, scale: Double = 1) -> Int? {
        guard value.hasSuffix(suffix) else { return nil }
        let number = value.dropLast(suffix.count)
        guard !number.isEmpty,
              number.allSatisfy({ $0.isNumber || $0 == "." }),
              let parsed = Double(number) else { return nil }
        return Int((parsed * scale).rounded())
    }

    private static let criticSites: [(site: String, score: @Sendable (Movie) -> Int?)] = [
        ("IMDb", { criticScore($0.imdb, suffix: "/10", scale: 10) }),
        ("Rotten Tomatoes", { criticScore($0.rottenTomatoes, suffix: "%") }),
        ("Metacritic", { criticScore($0.metacritic, suffix: "/100") }),
    ]

    private static func buildCritics(_ catalogue: [Movie]) -> [CriticSite] {
        criticSites.map { site, score in
            let gaps = catalogue
                .compactMap { movie -> CriticGap? in
                    guard let theirs = score(movie) else { return nil }
                    return CriticGap(title: movie.title, tmdbID: movie.tmdbID, mine: movie.score, theirs: theirs)
                }
                .sorted { ($0.mine - $0.theirs) > ($1.mine - $1.theirs) }
            return CriticSite(site: site,
                              higher: Array(gaps.prefix(criticGapSize)),
                              lower: Array(gaps.suffix(criticGapSize).reversed()))
        }
    }

    private static func average(_ movies: [Movie]) -> Double {
        movies.isEmpty ? 0 : Double(movies.reduce(0) { $0 + $1.score }) / Double(movies.count)
    }

    private static func buildDani(_ catalogue: [Movie]) -> DaniStats {
        let approved = catalogue.filter(\.daniApproved)
        let rest = catalogue.filter { !$0.daniApproved }

        var genreCounts: [String: (total: Int, approved: Int)] = [:]
        for movie in catalogue {
            for genre in movie.genres {
                var entry = genreCounts[genre] ?? (0, 0)
                entry.total += 1
                if movie.daniApproved { entry.approved += 1 }
                genreCounts[genre] = entry
            }
        }
        let topGenre = genreCounts
            .filter { $0.value.total >= daniGenreMinimum }
            .map { (label: $0.key, rate: Double($0.value.approved) / Double($0.value.total), total: $0.value.total) }
            .sorted { lhs, rhs in
                if lhs.rate != rhs.rate { return lhs.rate > rhs.rate }
                if lhs.total != rhs.total { return lhs.total > rhs.total }
                return lhs.label < rhs.label
            }
            .first
            .map { DaniStats.TopGenre(label: $0.label, rate: $0.rate) }

        return DaniStats(count: approved.count,
                         averageApproved: average(approved),
                         averageRest: average(rest),
                         topGenre: topGenre)
    }

    /// Highest score per year; ties go to the better overall ranking. Newest year first.
    private static func buildBestByYear(_ catalogue: [Movie]) -> [YearBest] {
        var byYear: [Int: Movie] = [:]
        for movie in catalogue {
            guard let current = byYear[movie.year] else {
                byYear[movie.year] = movie
                continue
            }
            if movie.score > current.score || (movie.score == current.score && movie.ranking < current.ranking) {
                byYear[movie.year] = movie
            }
        }
        return byYear
            .sorted { $0.key > $1.key }
            .map { YearBest(year: $0.key, movie: PosterMovie($0.value)) }
    }
}
