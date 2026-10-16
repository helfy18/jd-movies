import Foundation
import Testing
@testable import JD_Movies

struct PersonFilmographyTests {
    private let best = PosterMovie(title: "A", score: 90, poster: "", tmdbID: 1, daniApproved: true)
    private let worst = PosterMovie(title: "B", score: 40, poster: "", tmdbID: 2, daniApproved: false)

    @Test func combinesRolesWithoutDuplicates() {
        let filmography = PersonFilmography(name: "X", directed: [worst, best], actedIn: [best])
        #expect(filmography.rated.map(\.tmdbID) == [1, 2])
        #expect(filmography.directed.map(\.tmdbID) == [1, 2])
        #expect(filmography.movieCount == 2)
        #expect(filmography.averageScore == 65)
        #expect(filmography.best?.tmdbID == 1)
        #expect(filmography.worst?.tmdbID == 2)
        #expect(filmography.daniApprovedCount == 1)
    }

    @Test func singleMovieHasNoWorst() {
        let filmography = PersonFilmography(name: "Y", directed: [best], actedIn: [])
        #expect(filmography.worst == nil)
        #expect(!filmography.isEmpty)
    }

    @Test func scoreBuckets() {
        #expect(ScoreBuckets.counts(of: [10, 65, 66, 100]).map(\.count) == [1, 0, 0, 2, 0, 0, 1])
        let histogram = ScoreBuckets.histogram(Array(repeating: 1, count: SiteStats.bucketCount))
        #expect(histogram.first?.bucket.label == "0-4")
        #expect(histogram.last?.bucket.label == "95-100")
    }
}
