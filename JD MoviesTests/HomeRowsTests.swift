import Foundation
import Testing
@testable import JD_Movies

struct HomeRowsTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    private let catalogue: [Movie] = [
        .fixture(year: 2026, tmdbID: 1),
        .fixture(year: 2025, tmdbID: 2),
        .fixture(year: 1985, tmdbID: 3),
        .fixture(year: 1995, tmdbID: 4),
        .fixture(universe: "DC", tmdbID: 5),
        .fixture(universe: "Marvel", tmdbID: 6),
        .fixture(holiday: "Christmas", tmdbID: 7),
        .fixture(genre: "Horror", holiday: "Halloween", tmdbID: 8),
    ]

    private func titles(_ today: Date) -> [String] {
        HomeRows.build(catalogue: catalogue, today: today, calendar: calendar).map(\.title)
    }

    @Test func christmasRunsNovemberThroughDecember() {
        #expect(!HomeRows.isChristmasSeason(date(2026, 10, 31), calendar: calendar))
        #expect(HomeRows.isChristmasSeason(date(2026, 11, 1), calendar: calendar))
        #expect(HomeRows.isChristmasSeason(date(2026, 12, 31), calendar: calendar))
        #expect(!HomeRows.isChristmasSeason(date(2027, 1, 1), calendar: calendar))
    }

    @Test func halloweenCoversOctoberOnly() {
        #expect(!HomeRows.isHalloweenSeason(date(2026, 9, 30), calendar: calendar))
        #expect(HomeRows.isHalloweenSeason(date(2026, 10, 1), calendar: calendar))
        #expect(HomeRows.isHalloweenSeason(date(2026, 10, 31), calendar: calendar))
        #expect(!HomeRows.isHalloweenSeason(date(2026, 11, 1), calendar: calendar))
    }

    @Test func withRatingsPrefersTheRatedMovie() {
        let rated = Movie.fixture(title: "Rated", score: 88, tmdbID: 7)
        let result = HomeRows.withRatings([.fixture(id: 7)], rated: [7: rated])
        #expect(result == [PosterMovie(title: "Rated", score: 88, poster: rated.poster, tmdbID: 7, daniApproved: false)])
    }

    @Test func withRatingsBuildsUnratedPosters() {
        let result = HomeRows.withRatings([.fixture(id: 8)], rated: [:])
        #expect(result.count == 1)
        #expect(result.first?.score == Movie.unratedScore)
        #expect(result.first?.tmdbID == 8)
        #expect(result.first?.poster == "https://image.tmdb.org/t/p/w500/tmdb.jpg")
    }

    @Test func withRatingsDropsUnmatchedMoviesWithoutPosters() {
        #expect(HomeRows.withRatings([.fixture(id: 9, posterPath: nil)], rated: [:]).isEmpty)
    }

    @Test func alwaysIncludesYearDecadeAndUniverseRows() {
        #expect(titles(date(2026, 6, 15)) == [
            "Best of This Year", "Best of Last Year", "Best of the 80's", "Best of the 90's", "Best of DC", "Best of Marvel",
        ])
    }

    @Test func seasonalRows() {
        let october = titles(date(2026, 10, 15))
        let december = titles(date(2026, 12, 25))
        let june = titles(date(2026, 6, 15))
        #expect(october.contains("Best Halloween Movies") && october.contains("Spooky Season"))
        #expect(!june.contains("Best Halloween Movies") && !december.contains("Best Halloween Movies"))
        #expect(december.contains("Best Christmas Movies") && !october.contains("Best Christmas Movies"))
    }

    @Test func yearRowsFollowTheLatestCatalogueYear() {
        let rows = HomeRows.build(catalogue: catalogue, today: date(2026, 6, 15), calendar: calendar)
        let thisYear = rows.first { $0.title == "Best of This Year" }
        let lastYear = rows.first { $0.title == "Best of Last Year" }
        #expect(thisYear?.query == MovieListQuery(year: ["2026"]))
        #expect(thisYear?.movies.map(\.tmdbID) == [1])
        #expect(lastYear?.query == MovieListQuery(year: ["2025"]))
        #expect(lastYear?.movies.map(\.tmdbID) == [2])
    }

    @Test func rowsAreCappedAtTwenty() {
        let big = (1...30).map { Movie.fixture(year: 2026, tmdbID: $0) }
        let rows = HomeRows.build(catalogue: big, today: date(2026, 6, 15), calendar: calendar)
        #expect(rows.first { $0.title == "Best of This Year" }?.movies.count == HomeRows.rowLimit)
    }

    @Test func freeRowOnlyWhenFreeMoviesExist() {
        #expect(!titles(date(2026, 6, 15)).contains("Free to Watch"))
        let ads = Providers(link: "", rent: [], flatrate: [], buy: [], ads: [.fixture()], free: [])
        let rows = HomeRows.build(catalogue: catalogue + [.fixture(provider: ads, tmdbID: 9)],
                                  today: date(2026, 6, 15), calendar: calendar)
        let free = rows.first { $0.title == "Free to Watch" }
        #expect(free?.movies.map(\.tmdbID) == [9])
        #expect(free?.query == MovieListQuery(free: true))
    }

    @Test func daniRowOnlyWhenApprovedMoviesExist() {
        #expect(!titles(date(2026, 6, 15)).contains("Dani Approved"))
        let rows = HomeRows.build(catalogue: catalogue + [.fixture(daniApproved: true, tmdbID: 10)],
                                  today: date(2026, 6, 15), calendar: calendar)
        let dani = rows.first { $0.title == "Dani Approved" }
        #expect(dani?.movies.map(\.tmdbID) == [10])
        #expect(dani?.query == MovieListQuery(daniApproved: true))
    }

    @Test func emptyCatalogueHasNoRows() {
        #expect(HomeRows.build(catalogue: [], today: date(2026, 6, 15), calendar: calendar).isEmpty)
        #expect(HomeRows.build(catalogue: [], today: date(2026, 12, 25), calendar: calendar).isEmpty)
    }
}
