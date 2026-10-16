import SwiftUI

struct StatsView: View {
    @State private var model: StatsViewModel

    private let tileColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    init(repository: MovieRepository) {
        _model = State(initialValue: StatsViewModel(repository: repository))
    }

    var body: some View {
        ScrollView {
            switch model.state {
            case .idle, .loading:
                LoadingView()
            case .failed:
                ErrorView(message: "Couldn't load the stats.") {
                    await model.load(force: true)
                }
            case .loaded(let stats):
                content(stats)
            }
        }
        .screenBackground()
        .refreshable { await model.refresh() }
        .navigationTitle("Stats")
        .task { await model.load() }
    }

    private func content(_ stats: SiteStats) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            LazyVGrid(columns: tileColumns, spacing: 12) {
                HeroTile(value: "\(stats.movieCount)", label: "movies rated", route: .grid(.all))
                HeroTile(value: stats.runtimeDays.formatted(), label: "days of watching")
                HeroTile(value: stats.averageScore.formatted(.number.precision(.fractionLength(2))),
                         label: "average score", color: .score(stats.averageScore))
                HeroTile(value: stats.medianScore.formatted(), label: "median score", color: .score(stats.medianScore))
                HeroTile(value: "\(stats.perfectScores)", label: "perfect 100s",
                         route: .grid(MovieListQuery(rating: 100...100)))
            }
            .padding(.horizontal)

            section("By Score") {
                ScoreHistogramChart(distribution: stats.distribution)
                    .card()
            }
            section("By Decade") {
                ScrollView(.horizontal) {
                    CountBarsChart(data: stats.decades)
                }
                .scrollIndicators(.hidden)
                .card(alignment: .center)
            }
            section("By Genre") {
                ScrollView(.horizontal) {
                    CountBarsChart(data: stats.genres)
                }
                .scrollIndicators(.hidden)
                .card()
            }
            section("Dani Approved") {
                LazyVGrid(columns: tileColumns, spacing: 12) {
                    HeroTile(value: "\(stats.dani.count)", label: "movies approved",
                             route: .grid(MovieListQuery(daniApproved: true)))
                    HeroTile(value: "\(stats.dani.averageApproved.formatted(.number.precision(.fractionLength(2)))) vs \(stats.dani.averageRest.formatted(.number.precision(.fractionLength(2))))",
                             label: "approved avg vs the rest", color: .score(stats.dani.averageApproved))
                    if let top = stats.dani.topGenre {
                        HeroTile(value: top.label,
                                 label: "most approved genre (\(Int((top.rate * 100).rounded()))%)",
                                 route: .grid(MovieListQuery(genre: [top.label])))
                    }
                }
            }

            LeaderboardSection(title: "Directors (min \(SiteStats.minDirectorMovies) movies)",
                               boards: stats.directors) { .person($0.filterValue) }
                .padding(.horizontal)
            LeaderboardSection(title: "Actors (min \(SiteStats.minActorMovies) movies · averages count top-\(SiteStats.topBilling) billing only)",
                               boards: stats.actors) { .person($0.filterValue) }
                .padding(.horizontal)
            LeaderboardSection(title: "Universes (min \(SiteStats.minSubUniverseMovies) movies)",
                               boards: stats.subUniverses,
                               mostWatchedTitle: "Most Movies") { .grid(MovieListQuery(universe: [$0.filterValue])) }
                .padding(.horizontal)

            CriticsSection(critics: stats.critics)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                SectionTitle("Best of Each Year")
                    .padding(.horizontal)
                BestOfYearRow(items: stats.bestByYear)
            }
        }
        .padding(.vertical)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title)
            content()
        }
        .padding(.horizontal)
    }
}

#if DEBUG
#Preview {
    let ratings = StubRatingsService(onList: { _ in
        (1...60).map {
            Movie.fixture(title: "Movie \($0)", score: 40 + ($0 * 7) % 60, universe: $0 % 3 == 0 ? "Marvel" : "",
                          genre: ["Action", "Comedy", "Drama"][$0 % 3], year: 1980 + $0 % 45, ranking: $0,
                          daniApproved: $0 % 4 == 0, cast: ["Actor \($0 % 5)", "Actor \($0 % 7)"],
                          directors: ["Director \($0 % 6)"], tmdbID: $0, imdb: "\(5 + $0 % 5).0/10")
        }
    })
    NavigationStack {
        StatsView(repository: MovieRepository(ratings: ratings, tmdb: StubTMDBService()))
            .appDestinations()
    }
    .environment(AppEnvironment.preview(ratings: ratings))
    .preferredColorScheme(.dark)
}
#endif
