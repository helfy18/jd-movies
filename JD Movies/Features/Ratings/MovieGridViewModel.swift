import Foundation
import Observation

@MainActor
@Observable
final class MovieGridViewModel {
    private(set) var query: MovieListQuery
    var searchText = ""
    private(set) var movies: Loadable<SearchIndex> = .idle
    private(set) var filterTypes: Loadable<FilterTypes> = .idle

    private let repository: MovieRepository

    init(repository: MovieRepository, query: MovieListQuery = .all) {
        self.repository = repository
        self.query = query
    }

    /// The loaded list narrowed by the search text, best score first.
    var displayedMovies: [PosterMovie] {
        movies.value?.movies(matching: searchText).map(PosterMovie.init) ?? []
    }

    var peopleMatches: [SearchIndex.PersonMatch] {
        guard !searchText.isEmpty, let index = movies.value else { return [] }
        return index.people(matching: searchText)
    }

    var totalCount: Int {
        movies.value?.movies.count ?? 0
    }

    func load() async {
        let types = Task { await loadFilterTypes() }
        if movies.value == nil {
            await loadMovies()
        }
        await types.value
    }

    func apply(_ query: MovieListQuery) async {
        self.query = query
        await loadMovies()
    }

    func retry() async {
        await loadMovies()
    }

    private func loadMovies() async {
        let query = self.query
        movies = .loading
        do {
            let index = try await repository.searchIndex(for: query)
            guard query == self.query else { return }
            movies = .loaded(index)
        } catch {
            guard !Task.isCancelled, query == self.query else { return }
            movies = .failed(error)
        }
    }

    private func loadFilterTypes() async {
        guard filterTypes.value == nil else { return }
        filterTypes = .loading
        do {
            filterTypes = .loaded(try await repository.filterTypes())
        } catch {
            guard !Task.isCancelled else { return }
            filterTypes = .failed(error)
        }
    }
}
