import SwiftUI

struct RootTabView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                NavigationStack {
                    HomeView(repository: environment.repository)
                        .appDestinations()
                }
            }
            Tab("Ratings", systemImage: "square.grid.3x3.fill") {
                NavigationStack {
                    MovieGridView(repository: environment.repository)
                        .appDestinations()
                }
            }
            Tab("Random", systemImage: "dice.fill") {
                NavigationStack {
                    RandomMovieView(repository: environment.repository)
                        .appDestinations()
                }
            }
            Tab("Stats", systemImage: "chart.bar.fill") {
                NavigationStack {
                    StatsView(repository: environment.repository)
                        .appDestinations()
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    RootTabView()
        .environment(AppEnvironment.preview())
        .preferredColorScheme(.dark)
}
#endif
