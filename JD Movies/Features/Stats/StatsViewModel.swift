import Foundation
import Observation

@MainActor
@Observable
final class StatsViewModel {
    private(set) var state: Loadable<SiteStats> = .idle
    private let repository: MovieRepository

    init(repository: MovieRepository) {
        self.repository = repository
    }

    func load(force: Bool = false) async {
        guard force || state.value == nil else { return }
        state = .loading
        do {
            state = .loaded(try await repository.stats())
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error)
        }
    }

    func refresh() async {
        await repository.invalidate()
        await load(force: true)
    }
}
