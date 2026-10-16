import Foundation

/// A person's rated movies with the summary numbers the person screen shows.
nonisolated struct PersonFilmography: Hashable, Sendable {
    let name: String
    /// Sorted best to worst.
    let directed: [PosterMovie]
    /// Sorted best to worst.
    let actedIn: [PosterMovie]
    /// Every distinct movie across both roles, sorted best to worst.
    let rated: [PosterMovie]

    init(name: String, directed: [PosterMovie], actedIn: [PosterMovie]) {
        self.name = name
        self.directed = PersonFilmography.byScore(directed)
        self.actedIn = PersonFilmography.byScore(actedIn)
        var seen = Set<Int>()
        let unique = (directed + actedIn).filter { seen.insert($0.tmdbID).inserted }
        self.rated = PersonFilmography.byScore(unique)
    }

    var isEmpty: Bool { rated.isEmpty }
    var movieCount: Int { rated.count }
    var best: PosterMovie? { rated.first }
    /// `nil` when the worst movie is also the best (only one rated).
    var worst: PosterMovie? {
        guard let last = rated.last, last.tmdbID != best?.tmdbID else { return nil }
        return last
    }
    var daniApprovedCount: Int { rated.filter(\.daniApproved).count }
    var scores: [Int] { rated.map(\.score) }

    var averageScore: Double {
        guard !rated.isEmpty else { return 0 }
        return Double(rated.reduce(0) { $0 + $1.score }) / Double(rated.count)
    }

    private static func byScore(_ movies: [PosterMovie]) -> [PosterMovie] {
        movies.sorted { $0.score > $1.score }
    }
}
