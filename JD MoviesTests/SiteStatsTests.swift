import Foundation
import Testing
@testable import JD_Movies

struct SiteStatsTests {
    @Test func computesTotals() {
        let stats = SiteStats.build(from: [.fixture(score: 100, runtime: 1440), .fixture(score: 50, runtime: 720)])
        #expect(stats.movieCount == 2)
        #expect(stats.runtimeDays == 1.5)
        #expect(stats.averageScore == 75)
        #expect(stats.perfectScores == 1)
    }

    @Test func bucketsScoresWith100InTheLastBucket() {
        let stats = SiteStats.build(from: [0, 4, 5, 97, 100].map { Movie.fixture(score: $0) })
        #expect(stats.distribution.count == SiteStats.bucketCount)
        #expect(stats.distribution[0] == 2)
        #expect(stats.distribution[1] == 1)
        #expect(stats.distribution[SiteStats.bucketCount - 1] == 2)
        #expect(stats.distribution.reduce(0, +) == 5)
    }

    @Test func groupsDecadesInOrderAndCountsBothGenres() {
        let stats = SiteStats.build(from: [
            .fixture(score: 80, genre: "Drama", year: 1994),
            .fixture(score: 60, genre: "Drama", genre2: "Crime", year: 1999),
            .fixture(score: 90, genre: "Comic Book", year: 2008),
        ])
        #expect(stats.decades == [
            GroupStat(label: "1990s", count: 2, average: 70, query: MovieListQuery(decade: ["1990-1999"])),
            GroupStat(label: "2000s", count: 1, average: 90, query: MovieListQuery(decade: ["2000-2009"])),
        ])
        #expect(stats.genres == [
            GroupStat(label: "Drama", count: 2, average: 70, query: MovieListQuery(genre: ["Drama"])),
            GroupStat(label: "Comic Book", count: 1, average: 90, query: MovieListQuery(genre: ["Comic Book"])),
            GroupStat(label: "Crime", count: 1, average: 60, query: MovieListQuery(genre: ["Crime"])),
        ])
    }

    @Test func computesTheMedian() {
        let movies = [10, 40, 70, 100].enumerated().map { Movie.fixture(score: $0.element, tmdbID: $0.offset) }
        #expect(SiteStats.build(from: movies).medianScore == 55)
    }

    @Test func capsGenresIntoOther() {
        let movies = (0..<(SiteStats.genreLimit + 2)).map {
            Movie.fixture(score: 50 + $0, genre: String(format: "Genre %02d", $0), tmdbID: $0)
        }
        let stats = SiteStats.build(from: movies)
        #expect(stats.genres.count == SiteStats.genreLimit + 1)
        #expect(stats.genres.last?.label == "Other")
        #expect(stats.genres.last?.count == 2)
        #expect(stats.genres.last?.query == nil)
    }

    @Test func appliesMinimumCountsToLeaderboards() {
        let prolific = (0..<3).map { Movie.fixture(score: 90, directors: ["Threepeat"], tmdbID: $0) }
        let stats = SiteStats.build(from: prolific + [.fixture(score: 100, directors: ["One Hit"])])
        #expect(stats.directors.best == [PersonStat(name: "Threepeat", count: 3, average: 90, filter: nil)])
    }

    @Test func onlyTopBilledRolesCountTowardActorAverages() {
        let filler = (0..<10).map { "Filler \($0)" }
        let movies = (0..<5).map { Movie.fixture(score: 90, cast: filler + ["Cameo King"], tmdbID: $0) }
            + [.fixture(score: 90, cast: ["Cameo King"], tmdbID: 99)]
        let stats = SiteStats.build(from: movies)
        #expect(!stats.actors.best.map(\.name).contains("Cameo King"))
        #expect(!stats.actors.worst.map(\.name).contains("Cameo King"))
        #expect(stats.actors.mostWatched.map(\.name).contains("Cameo King"))
    }

    @Test func buildsCriticGapsFromParseableScores() {
        let stats = SiteStats.build(from: [
            .fixture(title: "Loved", score: 90, tmdbID: 1, imdb: "5.0/10"),
            .fixture(title: "Hated", score: 20, tmdbID: 2, imdb: "8.0/10"),
            .fixture(score: 50, tmdbID: 3, imdb: "N/A"),
        ])
        let imdb = stats.critics.first { $0.site == "IMDb" }
        #expect(imdb?.higher.first == CriticGap(title: "Loved", tmdbID: 1, mine: 90, theirs: 50))
        #expect(imdb?.lower.first == CriticGap(title: "Hated", tmdbID: 2, mine: 20, theirs: 80))
        #expect(imdb?.higher.count == 2)
    }

    @Test func parsesCriticScores() {
        #expect(SiteStats.criticScore("7.5/10", suffix: "/10", scale: 10) == 75)
        #expect(SiteStats.criticScore("85%", suffix: "%") == 85)
        #expect(SiteStats.criticScore("70/100", suffix: "/100") == 70)
        #expect(SiteStats.criticScore("N/A", suffix: "/10") == nil)
        #expect(SiteStats.criticScore("", suffix: "%") == nil)
    }

    @Test func computesDaniStats() {
        let stats = SiteStats.build(from: [
            .fixture(score: 90, daniApproved: true, tmdbID: 1),
            .fixture(score: 50, tmdbID: 2),
            .fixture(score: 70, tmdbID: 3),
        ])
        #expect(stats.dani.count == 1)
        #expect(stats.dani.averageApproved == 90)
        #expect(stats.dani.averageRest == 60)
        #expect(stats.dani.topGenre == nil)
    }

    @Test func picksTheBestMoviePerYearNewestFirst() {
        let stats = SiteStats.build(from: [
            .fixture(title: "Winner", score: 80, year: 2020, tmdbID: 1),
            .fixture(title: "Loser", score: 60, year: 2020, tmdbID: 2),
            .fixture(title: "Old", score: 95, year: 1999, tmdbID: 3),
        ])
        #expect(stats.bestByYear.map { "\($0.year) \($0.movie.title)" } == ["2020 Winner", "1999 Old"])
    }

    @Test func buildsSubUniverseLeaderboards() {
        let movies = (0..<3).map { Movie.fixture(score: 90, universe: "Marvel", subUniverse: "Spider-Verse", tmdbID: $0) }
            + [.fixture(score: 100, subUniverse: "One Off", tmdbID: 50)]
        #expect(SiteStats.build(from: movies).subUniverses.best == [
            PersonStat(name: "Marvel - Spider-Verse", count: 3, average: 90, filter: "Spider-Verse"),
        ])
    }

    @Test func doesNotDoubleTheLabelWhenSubUniverseMatchesUniverse() {
        let movies = (0..<3).map { Movie.fixture(score: 70, universe: "Disney Animation", subUniverse: "Disney Animation", tmdbID: $0) }
        #expect(SiteStats.build(from: movies).subUniverses.best.first?.name == "Disney Animation")
    }

    @Test func includesUniversesWithoutSubUniverses() {
        let movies = (0..<3).map { Movie.fixture(score: 80, universe: "John Wick", tmdbID: $0) }
        #expect(SiteStats.build(from: movies).subUniverses.best == [
            PersonStat(name: "John Wick", count: 3, average: 80, filter: "John Wick"),
        ])
    }

    @Test func ranksBestWorstAndMostWatchedIndependently() {
        let movies = (0..<5).map { Movie.fixture(score: 95, cast: ["Great", "Busy"], tmdbID: $0) }
            + (0..<5).map { Movie.fixture(score: 20, cast: ["Rough", "Busy"], tmdbID: 10 + $0) }
        let stats = SiteStats.build(from: movies)
        #expect(stats.actors.best.first?.name == "Great")
        #expect(stats.actors.worst.first?.name == "Rough")
        #expect(stats.actors.mostWatched.first == PersonStat(name: "Busy", count: 10, average: 57.5, filter: nil))
    }
}
