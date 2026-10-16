import Foundation

nonisolated enum RepositoryError: Error, LocalizedError, Sendable {
    case notFound
    case cacheTypeMismatch

    var errorDescription: String? {
        switch self {
        case .notFound: "Not found."
        case .cacheTypeMismatch: "Cached value had an unexpected type."
        }
    }
}

nonisolated struct TheatreListings: Hashable, Sendable {
    var nowPlaying: [TMDBMovie] = []
    var upcoming: [TMDBMovie] = []
}

/// The app's single source of movie data.
///
/// Wraps the ratings API and TMDB, de-duplicates in-flight requests and keeps
/// results for a while (the website revalidates its static pages on similar
/// intervals), so switching tabs never refetches the whole catalogue.
actor MovieRepository {
    static let shortTTL: TimeInterval = 15 * 60
    static let longTTL: TimeInterval = 60 * 60

    private struct Entry {
        let task: Task<any Sendable, any Error>
        let expires: Date

        var isFresh: Bool { expires > Date() }
    }

    private let ratings: any RatingsService
    private let tmdb: any TMDBService
    private var entries: [String: Entry] = [:]

    init(ratings: any RatingsService, tmdb: any TMDBService) {
        self.ratings = ratings
        self.tmdb = tmdb
    }

    /// Drops every cached value so the next request hits the network (pull to refresh).
    func invalidate() {
        entries.removeAll()
    }

    // MARK: - Ratings API

    /// Every rated movie, ranked best to worst.
    func catalogue() async throws -> [Movie] {
        try await cached("catalogue", ttl: Self.shortTTL) { [ratings] in
            try await ratings.list(.all)
        }
    }

    func compactList(_ query: MovieListQuery) async throws -> [CompactMovie] {
        try await cached("compact:\(Self.key(for: query))", ttl: Self.shortTTL) { [ratings] in
            try await ratings.compactList(query)
        }
    }

    /// A pre-folded search index for a compact list, built here so the main actor never pays for it.
    func searchIndex(for query: MovieListQuery) async throws -> SearchIndex {
        try await cached("index:\(Self.key(for: query))", ttl: Self.shortTTL) { [self] in
            let movies = try await compactList(query).sorted { $0.score > $1.score }
            return SearchIndex(movies: movies)
        }
    }

    func mostRecent() async throws -> [CompactMovie] {
        try await cached("recent", ttl: Self.shortTTL) { [ratings] in
            try await ratings.mostRecent(count: nil)
        }
    }

    func movieCount() async throws -> Int {
        try await cached("count", ttl: Self.shortTTL) { [ratings] in
            try await ratings.count()
        }
    }

    func filterTypes() async throws -> FilterTypes {
        try await cached("types", ttl: Self.longTTL) { [ratings] in
            try await ratings.filterTypes()
        }
    }

    func movies(tmdbIDs: [Int]) async throws -> [Movie] {
        guard !tmdbIDs.isEmpty else { return [] }
        let key = "movies:" + tmdbIDs.map(String.init).joined(separator: ",")
        return try await cached(key, ttl: Self.longTTL) { [ratings] in
            try await ratings.movies(tmdbIDs: tmdbIDs)
        }
    }

    /// A rated movie, or the TMDB version when the catalogue definitely does not have it.
    ///
    /// Only a 404 falls through to TMDB, so an outage on the ratings API never
    /// shows the unreviewed version of a rated movie.
    func movie(tmdbID: Int) async throws -> Movie {
        try await cached("movie:\(tmdbID)", ttl: Self.longTTL) { [ratings, tmdb] in
            do {
                return try await ratings.movie(tmdbID: tmdbID)
            } catch let error as HTTPError where error.isNotFound {
                let detail: TMDBMovieDetail
                do {
                    detail = try await tmdb.movieDetail(tmdbID: tmdbID)
                } catch let tmdbError as HTTPError where tmdbError.isNotFound {
                    throw RepositoryError.notFound
                }
                guard let movie = Movie(unrated: detail) else { throw RepositoryError.notFound }
                return movie
            }
        }
    }

    /// `nil` when no movie matches the filters. Never cached: every call is a new roll.
    func randomMovie(_ query: MovieListQuery) async throws -> Movie? {
        do {
            return try await ratings.random(query)
        } catch let error as HTTPError where error.isNotFound {
            return nil
        }
    }

    func stats() async throws -> SiteStats {
        try await cached("stats", ttl: Self.shortTTL) { [self] in
            SiteStats.build(from: try await catalogue())
        }
    }

    // MARK: - TMDB

    /// Now playing and upcoming. Empty when TMDB is unavailable, like the website.
    func theatreListings() async -> TheatreListings {
        let listings: TheatreListings? = try? await cached("theatre", ttl: Self.longTTL) { [tmdb] in
            async let nowPlaying = tmdb.nowPlaying()
            async let upcoming = tmdb.upcoming()
            return try await TheatreListings(nowPlaying: nowPlaying, upcoming: upcoming)
        }
        return listings ?? TheatreListings()
    }

    /// Bio and photo for a person, or `nil` when TMDB has nothing or is unavailable.
    func person(named name: String) async -> TMDBPerson? {
        let person: TMDBPerson?? = try? await cached("person:\(name)", ttl: Self.longTTL) { [tmdb] in
            try await tmdb.person(named: name)
        }
        return person ?? nil
    }

    // MARK: - Cache

    private func cached<Value: Sendable>(
        _ key: String,
        ttl: TimeInterval,
        _ load: @escaping @Sendable () async throws -> Value
    ) async throws -> Value {
        if let entry = entries[key], entry.isFresh,
           let value = try? await entry.task.value, let typed = value as? Value {
            return typed
        }
        let task = Task<any Sendable, any Error> {
            let value: any Sendable = try await load()
            return value
        }
        entries[key] = Entry(task: task, expires: Date().addingTimeInterval(ttl))
        do {
            guard let typed = try await task.value as? Value else { throw RepositoryError.cacheTypeMismatch }
            return typed
        } catch {
            if entries[key]?.task == task { entries[key] = nil }
            throw error
        }
    }

    private static func key(for query: MovieListQuery) -> String {
        query.queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
    }
}
