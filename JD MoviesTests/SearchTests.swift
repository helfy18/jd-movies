import Foundation
import Testing
@testable import JD_Movies

struct SearchTests {
    private let index = SearchIndex(movies: [
        .fixture(title: "The Batman", tmdbID: 1, cast: ["Zoë Kravitz"]),
        .fixture(title: "Amélie", tmdbID: 2, directors: ["Jean-Pierre Jeunet"]),
    ])

    @Test func matchesAccentedTextBothWays() {
        #expect(index.movies(matching: "zoe kravitz").map(\.tmdbID) == [1])
        #expect(index.movies(matching: "amelie").map(\.tmdbID) == [2])
        #expect(index.movies(matching: "Amélie").map(\.tmdbID) == [2])
    }

    @Test func searchesTitlesCastAndDirectorsCaseInsensitively() {
        #expect(index.movies(matching: "batman").count == 1)
        #expect(index.movies(matching: "jeunet").count == 1)
        #expect(index.movies(matching: "nolan").isEmpty)
        #expect(index.movies(matching: "").count == 2)
    }

    @Test func peopleAreRankedByAppearanceCount() {
        let people = SearchIndex(movies: [
            .fixture(tmdbID: 1, cast: ["Tom Hanks", "Zoë Saldaña"]),
            .fixture(tmdbID: 2, cast: ["Tom Hanks"], directors: ["Tom Hooper"]),
            .fixture(tmdbID: 3, cast: ["Tom Hardy"]),
        ])
        #expect(people.people(matching: "tom").map(\.name) == ["Tom Hanks", "Tom Hardy", "Tom Hooper"])
        #expect(people.people(matching: "saldana").map(\.name) == ["Zoë Saldaña"])
        #expect(people.people(matching: "t").isEmpty)
        #expect(people.people(matching: " ").isEmpty)
    }

    @Test func peopleMatchesAreCapped() {
        let crowd = SearchIndex(movies: (0..<10).map { CompactMovie.fixture(tmdbID: $0, cast: ["Match \($0)"]) })
        #expect(crowd.people(matching: "match").count == SearchIndex.personLimit)
    }
}
