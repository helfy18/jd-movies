import SwiftUI

struct RandomMovieView: View {
    @State private var model: RandomMovieViewModel
    @State private var showFilters = false

    init(repository: MovieRepository) {
        _model = State(initialValue: RandomMovieViewModel(repository: repository))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                controls
                switch model.state {
                case .idle, .loading:
                    LoadingView()
                case .failed:
                    ErrorView(message: "Couldn't load a movie.") {
                        await model.roll()
                    }
                case .loaded(nil):
                    MessageView("No movie matches these filters.")
                case .loaded(let movie?):
                    movieContent(movie)
                }
            }
            .padding()
            .holidayBackground(model.state.value??.holiday)
        }
        .screenBackground()
        .navigationTitle("Random Movie")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFilters) {
            if let options = model.filterTypes {
                FiltersSheet(options: options, query: model.query) { query in
                    Task { await model.apply(query) }
                }
            }
        }
        .task { await model.load() }
    }

    private var controls: some View {
        HStack(spacing: 16) {
            Button {
                Task { await model.roll() }
            } label: {
                Label("Next", systemImage: "dice")
                    .frame(maxWidth: .infinity)
            }
            .disabled(model.state.isLoading)

            Button {
                showFilters = true
            } label: {
                Label(model.query.isEmpty ? "Filters" : "Filters (\(model.query.activeFilterCount))",
                      systemImage: "line.3.horizontal.decrease.circle")
                    .frame(maxWidth: .infinity)
            }
            .disabled(model.filterTypes == nil)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    private func movieContent(_ movie: Movie) -> some View {
        VStack(spacing: 16) {
            NavigationLink(value: Route.movie(movie.tmdbID)) {
                RemoteImage(url: movie.posterURL(.w780), contentMode: .fit) {
                    PosterPlaceholder()
                }
                .aspectRatio(2 / 3, contentMode: .fit)
                .frame(maxWidth: 300)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    if movie.daniApproved {
                        DaniBadge(size: 64)
                    }
                }
            }
            .buttonStyle(.plain)

            Text(movie.title)
                .font(.title2.bold())
                .foregroundStyle(.appAccent)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                ScoreCard(label: "Ranking:",
                          value: "\(movie.ranking)",
                          total: model.totalCount.map(String.init) ?? "–",
                          score: movie.score)
                ScoreCard(label: "Score:",
                          value: "\(movie.score)",
                          total: "100",
                          score: movie.score)
            }
        }
    }
}

#if DEBUG
#Preview {
    let ratings = StubRatingsService(
        onCount: { 1204 },
        onRandom: { _ in .fixture(title: "Heat", score: 92, ranking: 12, daniApproved: true, tmdbID: 949) },
        onFilterTypes: { .fixture() }
    )
    NavigationStack {
        RandomMovieView(repository: MovieRepository(ratings: ratings, tmdb: StubTMDBService()))
            .appDestinations()
    }
    .environment(AppEnvironment.preview(ratings: ratings))
    .preferredColorScheme(.dark)
}
#endif
