import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    struct Content {
        var recent: [PosterMovie]
        var nowPlaying: [PosterMovie]
        var upcoming: [PosterMovie]
        var rows: [HomeRow]
    }

    private(set) var state: Loadable<Content> = .idle
    private let repository: MovieRepository

    init(repository: MovieRepository) {
        self.repository = repository
    }

    func load() async {
        guard state.value == nil else { return }
        state = .loading
        await fetch()
    }

    /// Pull to refresh: drop every cache and rebuild, keeping the old content on failure.
    func refresh() async {
        await repository.invalidate()
        await fetch()
    }

    private func fetch() async {
        do {
            state = .loaded(try await buildContent())
        } catch {
            guard !Task.isCancelled else { return }
            if state.value == nil { state = .failed(error) }
        }
    }

    private func buildContent() async throws -> Content {
        async let recent = repository.mostRecent()
        async let catalogue = repository.catalogue()
        async let theatre = repository.theatreListings()

        let listings = await theatre
        let theatreIDs = (listings.nowPlaying + listings.upcoming).map(\.id)
        let rated = try await repository.movies(tmdbIDs: theatreIDs)
        let ratedByID = Dictionary(rated.map { ($0.tmdbID, $0) }, uniquingKeysWith: { first, _ in first })

        return Content(
            recent: try await recent.map(PosterMovie.init),
            nowPlaying: HomeRows.withRatings(listings.nowPlaying, rated: ratedByID),
            upcoming: HomeRows.withRatings(listings.upcoming, rated: ratedByID),
            rows: HomeRows.build(catalogue: try await catalogue, today: Date())
        )
    }
}
