import Foundation
import Observation

@MainActor
@Observable
final class RandomMovieViewModel {
    private(set) var query: MovieListQuery = .all
    /// `.loaded(nil)` means no movie matches the current filters.
    private(set) var state: Loadable<Movie?> = .idle
    private(set) var filterTypes: FilterTypes?
    private(set) var totalCount: Int?

    private let repository: MovieRepository

    init(repository: MovieRepository) {
        self.repository = repository
    }

    func load() async {
        if case .idle = state {
            await roll()
        }
        if filterTypes == nil {
            filterTypes = try? await repository.filterTypes()
        }
        if totalCount == nil {
            totalCount = try? await repository.movieCount()
        }
    }

    /// Fetch another random movie for the current filters.
    func roll() async {
        state = .loading
        do {
            state = .loaded(try await repository.randomMovie(query))
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error)
        }
    }

    func apply(_ query: MovieListQuery) async {
        self.query = query
        await roll()
    }
}
