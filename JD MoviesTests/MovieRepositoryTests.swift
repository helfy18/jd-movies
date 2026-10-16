import Foundation
import Testing
@testable import JD_Movies

struct MovieRepositoryTests {
    private func makeRepository(listCalls: CallCounter = CallCounter()) -> MovieRepository {
        let ratings = StubRatingsService(
            onMovie: { id in
                if id == 1 { return .fixture(title: "Rated", tmdbID: 1) }
                if id == 500 { throw HTTPError.stub(500) }
                throw HTTPError.stub(404)
            },
            onList: { _ in
                await listCalls.increment()
                return [.fixture(tmdbID: 1)]
            }
        )
        let tmdb = StubTMDBService(
            onNowPlaying: { [.fixture(id: 10)] },
            onUpcoming: { throw HTTPError.stub(503) },
            onMovieDetail: { id in id == 2 ? .fixture(id: 2, title: "Unrated") : .fixture(id: id, adult: true) }
        )
        return MovieRepository(ratings: ratings, tmdb: tmdb)
    }

    @Test func servesRatedMovies() async throws {
        #expect(try await makeRepository().movie(tmdbID: 1).title == "Rated")
    }

    @Test func fallsBackToTMDBOnlyOn404() async throws {
        let repository = makeRepository()
        let fallback = try await repository.movie(tmdbID: 2)
        #expect(fallback.title == "Unrated")
        #expect(!fallback.isRated)

        await #expect(throws: RepositoryError.notFound) {
            _ = try await repository.movie(tmdbID: 3)
        }
        await #expect(throws: HTTPError.stub(500)) {
            _ = try await repository.movie(tmdbID: 500)
        }
    }

    @Test func cachesAndCoalescesTheCatalogue() async throws {
        let calls = CallCounter()
        let repository = makeRepository(listCalls: calls)
        async let first = repository.catalogue()
        async let second = repository.catalogue()
        _ = try await (first, second)
        _ = try await repository.stats()
        #expect(await calls.count == 1)

        await repository.invalidate()
        _ = try await repository.catalogue()
        #expect(await calls.count == 2)
    }

    @Test func randomReturnsNilWhenNothingMatches() async throws {
        #expect(try await makeRepository().randomMovie(.all) == nil)
    }

    @Test func tmdbFailuresDegradeGracefully() async {
        let repository = makeRepository()
        let listings = await repository.theatreListings()
        #expect(listings.nowPlaying.isEmpty && listings.upcoming.isEmpty)
        #expect(await repository.person(named: "Nobody") == nil)
    }
}
