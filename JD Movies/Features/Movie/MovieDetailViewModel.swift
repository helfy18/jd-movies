import Foundation
import Observation

@MainActor
@Observable
final class MovieDetailViewModel {
    let tmdbID: Int
    private(set) var state: Loadable<Movie> = .idle
    private(set) var recommended: [PosterMovie] = []
    private(set) var totalCount: Int?

    private let repository: MovieRepository

    init(repository: MovieRepository, tmdbID: Int) {
        self.repository = repository
        self.tmdbID = tmdbID
    }

    func load(force: Bool = false) async {
        guard force || state.value == nil else { return }
        state = .loading
        do {
            let movie = try await repository.movie(tmdbID: tmdbID)
            state = .loaded(movie)
            async let recommendations = repository.movies(tmdbIDs: movie.recommendations)
            async let count = repository.movieCount()
            recommended = ((try? await recommendations) ?? []).map(PosterMovie.init)
            totalCount = try? await count
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error)
        }
    }

    var errorMessage: String {
        if case .failed(let error) = state, case RepositoryError.notFound = error {
            return "This movie isn't in the catalogue."
        }
        return "Couldn't load this movie."
    }
}
