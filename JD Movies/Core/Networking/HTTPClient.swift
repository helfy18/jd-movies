import Foundation

/// The one seam between the API clients and the network, so tests can stub responses.
nonisolated protocol HTTPClient: Sendable {
    func data(from url: URL) async throws -> Data
}

/// A non-2xx response. `isNotFound` drives the TMDB fallback and "no match" states.
nonisolated struct HTTPError: Error, Hashable, Sendable, LocalizedError {
    let statusCode: Int
    let url: URL

    var isNotFound: Bool { statusCode == 404 }

    var errorDescription: String? {
        "\(statusCode) \(HTTPURLResponse.localizedString(forStatusCode: statusCode))"
    }
}

nonisolated struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw HTTPError(statusCode: http.statusCode, url: url)
        }
        return data
    }
}

nonisolated enum Endpoint {
    /// Appends a path and query to a base URL. Empty queries produce no `?`.
    static func url(base: URL, path: String, query: [URLQueryItem] = []) throws -> URL {
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let withPath = base.appending(path: trimmed)
        guard var components = URLComponents(url: withPath, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        components.queryItems = query.isEmpty ? nil : query
        guard let url = components.url else { throw URLError(.badURL) }
        return url
    }
}

/// Fetches and decodes JSON off the caller's actor so large payloads never block the UI.
nonisolated struct JSONTransport: Sendable {
    let http: any HTTPClient

    init(http: any HTTPClient = URLSessionHTTPClient()) {
        self.http = http
    }

    @concurrent
    func get<Value: Decodable & Sendable>(_ type: Value.Type = Value.self, from url: URL) async throws -> Value {
        let data = try await http.data(from: url)
        return try JSONDecoder().decode(Value.self, from: data)
    }
}
