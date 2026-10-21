#if DEBUG
import Foundation

// Test data and scripted services shared by unit tests and SwiftUI previews.
// Compiled into debug builds only.

nonisolated extension HTTPError {
    static func stub(_ statusCode: Int) -> HTTPError {
        HTTPError(statusCode: statusCode, url: URL(fileURLWithPath: "/stub"))
    }
}

nonisolated extension Movie {
    static func fixture(
        title: String = "Test Movie",
        score: Int = 75,
        universe: String = "",
        subUniverse: String = "",
        genre: String = "Action",
        genre2: String = "",
        holiday: String = "",
        exclusive: String = "",
        studio: String = "",
        year: Int = 2020,
        review: String = "",
        ranking: Int = 1,
        daniApproved: Bool = false,
        plot: String = "",
        poster: String = "https://image.tmdb.org/t/p/w500/test.jpg",
        cast: [CastMember] = [],
        directors: [String] = [],
        runtime: Int = 120,
        provider: Providers = .none,
        tmdbID: Int = 1,
        recommendations: [Int] = [],
        rottenTomatoes: String = "",
        imdb: String = "",
        metacritic: String = "",
        trailer: String = ""
    ) -> Movie {
        Movie(title: title, score: score, universe: universe, subUniverse: subUniverse, genre: genre,
              genre2: genre2, holiday: holiday, exclusive: exclusive, studio: studio, year: year,
              review: review, ranking: ranking, daniApproved: daniApproved, plot: plot, poster: poster,
              cast: cast, directors: directors, ratings: [], boxOffice: "", rated: "", runtime: runtime,
              provider: provider, budget: "", tmdbID: tmdbID, recommendations: recommendations,
              rottenTomatoes: rottenTomatoes, imdb: imdb, metacritic: metacritic, trailer: trailer)
    }
}

nonisolated extension CompactMovie {
    static func fixture(
        title: String = "Test Movie",
        score: Int = 75,
        poster: String = "https://image.tmdb.org/t/p/w500/test.jpg",
        tmdbID: Int = 1,
        daniApproved: Bool = false,
        cast: [CastMember] = [],
        directors: [String] = [],
        universe: String = "",
        subUniverse: String = "",
        studio: String = "",
        year: Int = 2020
    ) -> CompactMovie {
        CompactMovie(title: title, score: score, poster: poster, tmdbID: tmdbID, daniApproved: daniApproved,
                     cast: cast, directors: directors, universe: universe, subUniverse: subUniverse,
                     studio: studio, year: year)
    }
}

nonisolated extension CastMember {
    /// Name-only members, the shape compact lists and pre-migration documents carry.
    static func names(_ names: String...) -> [CastMember] {
        names.map { CastMember(name: $0) }
    }

    static func names(_ names: [String]) -> [CastMember] {
        names.map { CastMember(name: $0) }
    }
}

nonisolated extension TMDBMovie {
    static func fixture(id: Int = 99, title: String = "TMDB Movie", posterPath: String? = "/tmdb.jpg") -> TMDBMovie {
        TMDBMovie(id: id, title: title, posterPath: posterPath, releaseDate: "2024-01-01")
    }
}

nonisolated extension TMDBMovieDetail {
    static func fixture(id: Int = 500, title: String = "Unrated Movie", adult: Bool = false) -> TMDBMovieDetail {
        TMDBMovieDetail(adult: adult, budget: 1_000_000, genres: [TMDBGenre(id: 1, name: "Drama")], id: id,
                        overview: "An overview.", posterPath: "/unrated.jpg", releaseDate: "2023-05-01",
                        revenue: 0, runtime: 101, title: title,
                        credits: TMDBCredits(cast: [TMDBCastMember(name: "Lead Actor")],
                                             crew: [TMDBCrewMember(name: "The Director", job: "Director")]),
                        videos: TMDBPage(results: [TMDBVideo(key: "abc123", site: "YouTube", type: "Trailer")]),
                        watchProviders: nil, releaseDates: nil, recommendations: nil)
    }
}

nonisolated extension ProviderInfo {
    static func fixture(id: Int = 1, name: String = "Tubi TV") -> ProviderInfo {
        ProviderInfo(logoPath: "/logo.jpg", providerID: id, providerName: name, displayPriority: 1)
    }
}

nonisolated extension FilterTypes {
    static func fixture() -> FilterTypes {
        FilterTypes(
            director: [FilterCount(fieldValue: "Steven Spielberg", totalCount: 12),
                       FilterCount(fieldValue: "Greta Gerwig", totalCount: 3)],
            exclusive: ["Netflix"],
            genre: [FilterCount(fieldValue: "Action", totalCount: 120),
                    FilterCount(fieldValue: "Comedy", totalCount: 90),
                    FilterCount(fieldValue: "Western", totalCount: 4)],
            holiday: ["Christmas", "Halloween"],
            runtime: [RuntimeRange(min: 60, max: 240)],
            provider: [.fixture(id: 8, name: "Netflix"), .fixture(id: 337, name: "Disney Plus")],
            studio: ["Pixar", "A24"],
            universes: [
                UniverseType(fieldValue: "Marvel",
                             subUniverses: [FilterCount(fieldValue: "X-Men", totalCount: 10),
                                            FilterCount(fieldValue: "MCU", totalCount: 30)],
                             totalCount: 45),
                UniverseType(fieldValue: "John Wick", totalCount: 4),
            ],
            year: [2024, 2023, 1999, 1985]
        )
    }
}

/// Counts calls across actors so tests can assert on caching and de-duplication.
actor CallCounter {
    private(set) var count = 0

    func increment() {
        count += 1
    }
}

/// A ratings service scripted with closures. Everything 404s until configured.
nonisolated struct StubRatingsService: RatingsService {
    var onMovie: @Sendable (Int) async throws -> Movie = { _ in throw HTTPError.stub(404) }
    var onMovies: @Sendable ([Int]) async throws -> [Movie] = { _ in [] }
    var onCount: @Sendable () async throws -> Int = { 0 }
    var onList: @Sendable (MovieListQuery) async throws -> [Movie] = { _ in [] }
    var onCompactList: @Sendable (MovieListQuery) async throws -> [CompactMovie] = { _ in [] }
    var onMostRecent: @Sendable (Int?) async throws -> [CompactMovie] = { _ in [] }
    var onRandom: @Sendable (MovieListQuery) async throws -> Movie = { _ in throw HTTPError.stub(404) }
    var onFilterTypes: @Sendable () async throws -> FilterTypes = { FilterTypes() }

    func movie(tmdbID: Int) async throws -> Movie { try await onMovie(tmdbID) }
    func movies(tmdbIDs: [Int]) async throws -> [Movie] { try await onMovies(tmdbIDs) }
    func count() async throws -> Int { try await onCount() }
    func list(_ query: MovieListQuery) async throws -> [Movie] { try await onList(query) }
    func compactList(_ query: MovieListQuery) async throws -> [CompactMovie] { try await onCompactList(query) }
    func mostRecent(count: Int?) async throws -> [CompactMovie] { try await onMostRecent(count) }
    func random(_ query: MovieListQuery) async throws -> Movie { try await onRandom(query) }
    func filterTypes() async throws -> FilterTypes { try await onFilterTypes() }
}

nonisolated struct StubTMDBService: TMDBService {
    var onNowPlaying: @Sendable () async throws -> [TMDBMovie] = { [] }
    var onUpcoming: @Sendable () async throws -> [TMDBMovie] = { [] }
    var onMovieDetail: @Sendable (Int) async throws -> TMDBMovieDetail = { _ in throw HTTPError.stub(404) }
    var onPerson: @Sendable (String) async throws -> TMDBPerson? = { _ in nil }

    func nowPlaying() async throws -> [TMDBMovie] { try await onNowPlaying() }
    func upcoming() async throws -> [TMDBMovie] { try await onUpcoming() }
    func movieDetail(tmdbID: Int) async throws -> TMDBMovieDetail { try await onMovieDetail(tmdbID) }
    func person(named name: String) async throws -> TMDBPerson? { try await onPerson(name) }
}
#endif
