import Foundation

/// The parts of TMDB the app uses: theatre listings, unrated movie details and person bios.
nonisolated protocol TMDBService: Sendable {
    func nowPlaying() async throws -> [TMDBMovie]
    func upcoming() async throws -> [TMDBMovie]
    func movieDetail(tmdbID: Int) async throws -> TMDBMovieDetail
    func person(named name: String) async throws -> TMDBPerson?
}

nonisolated enum TMDBError: Error, LocalizedError, Sendable {
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: "TMDB API key is not configured."
        }
    }
}

nonisolated struct TMDBAPIClient: TMDBService {
    private static let baseURL = URL(string: "https://api.themoviedb.org/3")!
    private static let region = "US"

    private let apiKey: String
    private let transport: JSONTransport

    init(apiKey: String, http: any HTTPClient = URLSessionHTTPClient()) {
        self.apiKey = apiKey
        self.transport = JSONTransport(http: http)
    }

    private func url(_ path: String, _ query: [URLQueryItem] = []) throws -> URL {
        let common = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "region", value: Self.region),
        ]
        return try Endpoint.url(base: Self.baseURL, path: path, query: common + query)
    }

    func nowPlaying() async throws -> [TMDBMovie] {
        try await transport.get(TMDBPage<TMDBMovie>.self, from: url("/movie/now_playing")).results
    }

    func upcoming() async throws -> [TMDBMovie] {
        try await transport.get(TMDBPage<TMDBMovie>.self, from: url("/movie/upcoming")).results
    }

    func movieDetail(tmdbID: Int) async throws -> TMDBMovieDetail {
        let append = URLQueryItem(name: "append_to_response",
                                  value: "credits,videos,watch/providers,release_dates,recommendations")
        return try await transport.get(from: url("/movie/\(tmdbID)", [append]))
    }

    func person(named name: String) async throws -> TMDBPerson? {
        let search: TMDBPage<TMDBPersonResult> = try await transport.get(
            from: url("/search/person", [URLQueryItem(name: "query", value: name)])
        )
        guard let first = search.results.first else { return nil }
        return try await transport.get(from: url("/person/\(first.id)"))
    }
}

/// Used when no TMDB key is configured: every call fails fast and the UI degrades gracefully.
nonisolated struct UnavailableTMDBService: TMDBService {
    func nowPlaying() async throws -> [TMDBMovie] { throw TMDBError.missingAPIKey }
    func upcoming() async throws -> [TMDBMovie] { throw TMDBError.missingAPIKey }
    func movieDetail(tmdbID: Int) async throws -> TMDBMovieDetail { throw TMDBError.missingAPIKey }
    func person(named name: String) async throws -> TMDBPerson? { throw TMDBError.missingAPIKey }
}
