import SwiftUI

/// Every screen that can be pushed onto a tab's navigation stack.
nonisolated enum Route: Hashable, Sendable {
    case movie(Int)
    case person(String)
    case grid(MovieListQuery)
}

/// Resolves a `Route` to its screen using the shared environment.
struct RouteView: View {
    let route: Route
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        switch route {
        case .movie(let tmdbID):
            MovieDetailView(repository: environment.repository, tmdbID: tmdbID)
        case .person(let name):
            PersonView(repository: environment.repository, name: name)
        case .grid(let query):
            MovieGridView(repository: environment.repository, query: query)
        }
    }
}

extension View {
    /// Apply once to the root of each `NavigationStack` so `NavigationLink(value: Route)` works anywhere below it.
    func appDestinations() -> some View {
        navigationDestination(for: Route.self) { RouteView(route: $0) }
    }
}
