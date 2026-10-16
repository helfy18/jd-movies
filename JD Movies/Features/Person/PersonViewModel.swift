import Foundation
import Observation

@MainActor
@Observable
final class PersonViewModel {
    let name: String
    private(set) var state: Loadable<PersonFilmography> = .idle
    private(set) var person: TMDBPerson?

    private let repository: MovieRepository

    init(repository: MovieRepository, name: String) {
        self.repository = repository
        self.name = name
    }

    func load(force: Bool = false) async {
        guard force || state.value == nil else { return }
        state = .loading
        do {
            async let directed = repository.compactList(MovieListQuery(director: [name]))
            async let actedIn = repository.compactList(MovieListQuery(actor: [name]))
            let filmography = PersonFilmography(name: name,
                                                directed: try await directed.map(PosterMovie.init),
                                                actedIn: try await actedIn.map(PosterMovie.init))
            state = .loaded(filmography)
            person = await repository.person(named: name)
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error)
        }
    }
}
