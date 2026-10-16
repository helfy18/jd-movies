import Foundation

/// Filter parameters accepted by `/movies/list` and `/movies/random`.
nonisolated struct MovieListQuery: Hashable, Sendable {
    var genre: [String] = []
    var universe: [String] = []
    var exclusive: [String] = []
    var studio: [String] = []
    var holiday: [String] = []
    var year: [String] = []
    var director: [String] = []
    var actor: [String] = []
    var decade: [String] = []
    var provider: [String] = []
    var runtime: ClosedRange<Int>?
    var rating: ClosedRange<Int>?
    var free = false
    var daniApproved = false

    static let all = MovieListQuery()

    var isEmpty: Bool { self == MovieListQuery.all }

    /// Number of filter groups in use, for the "Filters" badge.
    var activeFilterCount: Int {
        let lists = [genre, universe, exclusive, studio, holiday, year, director, actor, decade, provider]
        return lists.filter { !$0.isEmpty }.count
            + (runtime == nil ? 0 : 1)
            + (rating == nil ? 0 : 1)
            + (free ? 1 : 0)
            + (daniApproved ? 1 : 0)
    }

    /// Repeated keys for lists, two values for ranges, `true` for flags, matching the website.
    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        func add(_ name: String, _ values: [String]) {
            items += values.map { URLQueryItem(name: name, value: $0) }
        }
        add("genre", genre)
        add("universe", universe)
        add("exclusive", exclusive)
        add("studio", studio)
        add("holiday", holiday)
        add("year", year)
        add("director", director)
        add("actor", actor)
        add("decade", decade)
        add("provider", provider)
        if let runtime {
            add("runtime", [String(runtime.lowerBound), String(runtime.upperBound)])
        }
        if let rating {
            add("rating", [String(rating.lowerBound), String(rating.upperBound)])
        }
        if free { items.append(URLQueryItem(name: "free", value: "true")) }
        if daniApproved { items.append(URLQueryItem(name: "dani_approved", value: "true")) }
        return items
    }

    static func decade(startingAt start: Int) -> MovieListQuery {
        MovieListQuery(decade: ["\(start)-\(start + 9)"])
    }
}
