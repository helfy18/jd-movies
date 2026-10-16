import Foundation

/// The ratings API: Johnathan's catalogue of reviewed movies.
nonisolated protocol RatingsService: Sendable {
    func movie(tmdbID: Int) async throws -> Movie
    func movies(tmdbIDs: [Int]) async throws -> [Movie]
    func count() async throws -> Int
    func list(_ query: MovieListQuery) async throws -> [Movie]
    func compactList(_ query: MovieListQuery) async throws -> [CompactMovie]
    func mostRecent(count: Int?) async throws -> [CompactMovie]
    func random(_ query: MovieListQuery) async throws -> Movie
    func filterTypes() async throws -> FilterTypes
}

nonisolated struct RatingsAPIClient: RatingsService {
    private let baseURL: URL
    private let transport: JSONTransport

    init(baseURL: URL, http: any HTTPClient = URLSessionHTTPClient()) {
        self.baseURL = baseURL
        self.transport = JSONTransport(http: http)
    }

    private func url(_ path: String, _ query: [URLQueryItem] = []) throws -> URL {
        try Endpoint.url(base: baseURL, path: path, query: query)
    }

    private static let compactView = URLQueryItem(name: "view", value: "compact")

    func movie(tmdbID: Int) async throws -> Movie {
        try await transport.get(from: url("/movies/get", [URLQueryItem(name: "tmdbid", value: String(tmdbID))]))
    }

    func movies(tmdbIDs: [Int]) async throws -> [Movie] {
        guard !tmdbIDs.isEmpty else { return [] }
        let items = tmdbIDs.map { URLQueryItem(name: "tmdbid", value: String($0)) }
        return try await transport.get(from: url("/movies/list/id", items))
    }

    func count() async throws -> Int {
        try await transport.get(from: url("/movies/count"))
    }

    func list(_ query: MovieListQuery) async throws -> [Movie] {
        try await transport.get(from: url("/movies/list", query.queryItems))
    }

    func compactList(_ query: MovieListQuery) async throws -> [CompactMovie] {
        try await transport.get(from: url("/movies/list", query.queryItems + [Self.compactView]))
    }

    func mostRecent(count: Int? = nil) async throws -> [CompactMovie] {
        var items = [Self.compactView]
        if let count { items.append(URLQueryItem(name: "count", value: String(count))) }
        return try await transport.get(from: url("/movies/mostRecent", items))
    }

    func random(_ query: MovieListQuery) async throws -> Movie {
        try await transport.get(from: url("/movies/random", query.queryItems))
    }

    func filterTypes() async throws -> FilterTypes {
        try await transport.get(from: url("/types/list"))
    }
}
