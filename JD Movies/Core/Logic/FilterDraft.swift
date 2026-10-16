import Foundation

/// The editable state of the filter sheet. Converts to and from `MovieListQuery`,
/// dropping ranges that still span their full bounds so they are not sent to the API.
nonisolated struct FilterDraft: Hashable, Sendable {
    static let scoreBounds: ClosedRange<Double> = 0...100

    var genres: Set<String> = []
    var universes: Set<String> = []
    var directors: Set<String> = []
    var studios: Set<String> = []
    var years: Set<String> = []
    var providers: Set<String> = []
    var holidays: Set<String> = []
    var decades: Set<String> = []
    var runtime: ClosedRange<Double>
    var score: ClosedRange<Double> = FilterDraft.scoreBounds
    var free = false
    var daniApproved = false

    let runtimeBounds: ClosedRange<Double>

    init(query: MovieListQuery = .all, runtimeBounds: ClosedRange<Int>) {
        self.runtimeBounds = Double(runtimeBounds.lowerBound)...Double(runtimeBounds.upperBound)
        genres = Set(query.genre)
        universes = Set(query.universe)
        directors = Set(query.director)
        studios = Set(query.studio)
        years = Set(query.year)
        providers = Set(query.provider)
        holidays = Set(query.holiday)
        decades = Set(query.decade)
        runtime = query.runtime.map(FilterDraft.doubles) ?? self.runtimeBounds
        score = query.rating.map(FilterDraft.doubles) ?? FilterDraft.scoreBounds
        free = query.free
        daniApproved = query.daniApproved
    }

    /// Clears every selection while keeping the slider bounds.
    mutating func reset() {
        self = FilterDraft(runtimeBounds: FilterDraft.ints(runtimeBounds))
    }

    var query: MovieListQuery {
        var query = MovieListQuery(
            genre: genres.sorted(),
            universe: universes.sorted(),
            studio: studios.sorted(),
            holiday: holidays.sorted(),
            year: years.sorted(),
            director: directors.sorted(),
            decade: decades.sorted(),
            provider: providers.sorted()
        )
        if runtime != runtimeBounds { query.runtime = FilterDraft.ints(runtime) }
        if score != FilterDraft.scoreBounds { query.rating = FilterDraft.ints(score) }
        query.free = free
        query.daniApproved = daniApproved
        return query
    }

    private static func doubles(_ range: ClosedRange<Int>) -> ClosedRange<Double> {
        Double(range.lowerBound)...Double(range.upperBound)
    }

    private static func ints(_ range: ClosedRange<Double>) -> ClosedRange<Int> {
        let lower = Int(range.lowerBound.rounded())
        let upper = Int(range.upperBound.rounded())
        return lower...max(lower, upper)
    }
}
