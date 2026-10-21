import Foundation

/// Client-side text search over the compact catalogue, accent- and case-insensitive.
///
/// Build one `SearchIndex` per loaded list; it pre-folds every searchable string
/// so typing in the search field stays cheap even with thousands of movies.
nonisolated struct SearchIndex: Sendable {
    static let personLimit = 6
    static let personMinimumLength = 2

    nonisolated struct PersonMatch: Hashable, Sendable, Identifiable {
        let name: String
        let count: Int

        var id: String { name }
    }

    private struct MovieEntry: Sendable {
        let movie: CompactMovie
        let haystack: [String]
    }

    private struct PersonEntry: Sendable {
        let name: String
        let folded: String
        let count: Int
    }

    private let movieEntries: [MovieEntry]
    private let personEntries: [PersonEntry]

    /// Every indexed movie, in the order given.
    var movies: [CompactMovie] { movieEntries.map(\.movie) }

    init(movies: [CompactMovie]) {
        movieEntries = movies.map { movie in
            let fields = [movie.title, movie.universe, movie.subUniverse, movie.studio] + movie.castNames + movie.directors
            return MovieEntry(movie: movie, haystack: fields.map(SearchIndex.fold))
        }
        var counts: [String: Int] = [:]
        for movie in movies {
            for name in Set(movie.castNames + movie.directors) {
                counts[name, default: 0] += 1
            }
        }
        personEntries = counts.map { PersonEntry(name: $0.key, folded: SearchIndex.fold($0.key), count: $0.value) }
    }

    /// Lower-cases and strips diacritics so "Amelie" matches "Amélie" and vice versa.
    static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }

    /// Movies whose title, cast, directors, universe, sub-universe or studio contain the text.
    func movies(matching text: String) -> [CompactMovie] {
        let needle = SearchIndex.fold(text)
        guard !needle.isEmpty else { return movies }
        return movieEntries
            .filter { entry in entry.haystack.contains { $0.contains(needle) } }
            .map(\.movie)
    }

    /// Actors and directors matching the text, ranked by how many movies they appear in.
    func people(matching text: String) -> [PersonMatch] {
        let needle = SearchIndex.fold(text.trimmingCharacters(in: .whitespacesAndNewlines))
        guard needle.count >= SearchIndex.personMinimumLength else { return [] }
        return personEntries
            .filter { $0.folded.contains(needle) }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                return lhs.name.localizedCompare(rhs.name) == .orderedAscending
            }
            .prefix(SearchIndex.personLimit)
            .map { PersonMatch(name: $0.name, count: $0.count) }
    }
}
