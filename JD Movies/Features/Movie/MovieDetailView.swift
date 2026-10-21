import SwiftUI

struct MovieDetailView: View {
    @State private var model: MovieDetailViewModel
    @State private var showDani = false
    @Environment(AppEnvironment.self) private var environment

    init(repository: MovieRepository, tmdbID: Int) {
        _model = State(initialValue: MovieDetailViewModel(repository: repository, tmdbID: tmdbID))
    }

    var body: some View {
        ScrollView {
            switch model.state {
            case .idle, .loading:
                LoadingView()
            case .failed:
                ErrorView(message: model.errorMessage) {
                    await model.load(force: true)
                }
            case .loaded(let movie):
                content(movie)
            }
        }
        .screenBackground()
        .navigationTitle(model.state.value?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let movie = model.state.value {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: environment.configuration.movieURL(tmdbID: movie.tmdbID))
                }
            }
        }
        .sheet(isPresented: $showDani) {
            DaniSheet()
        }
        .task { await model.load() }
    }

    private func content(_ movie: Movie) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            posterSection(movie)
            MovieInfoSection(movie: movie)
                .padding(.horizontal)
            ProvidersSection(movie: movie)
                .padding(.horizontal)
            if let trailer = movie.trailerURL {
                VStack(alignment: .trailing, spacing: 6) {
                    TrailerPlayer(url: trailer, referrer: environment.configuration.siteBaseURL)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    if let watch = movie.trailerWatchURL {
                        Link(destination: watch) {
                            Label("Watch on YouTube", systemImage: "play.rectangle")
                                .font(.footnote)
                        }
                    }
                }
                .padding(.horizontal)
            }
            if !movie.plot.isEmpty {
                TextBlock(title: "Plot", text: movie.plot)
                    .padding(.horizontal)
            }
            if let review = movie.review.nonEmpty {
                TextBlock(title: "Review", text: review)
                    .padding(.horizontal)
            }
            OtherSiteReviews(movie: movie)
                .padding(.horizontal)
            if !movie.cast.isEmpty {
                CastSection(cast: movie.cast)
            }
            if !model.recommended.isEmpty {
                PosterRow(title: "More Like This", movies: model.recommended)
            }
        }
        .padding(.vertical)
        .holidayBackground(movie.holiday)
    }

    private func posterSection(_ movie: Movie) -> some View {
        VStack(spacing: 16) {
            RemoteImage(url: movie.posterURL(.w780), contentMode: .fit) {
                PosterPlaceholder()
            }
            .aspectRatio(2 / 3, contentMode: .fit)
            .frame(maxWidth: 260)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if movie.daniApproved {
                    Button {
                        showDani = true
                    } label: {
                        DaniBadge(size: 72)
                    }
                    .buttonStyle(.plain)
                }
            }

            if movie.isRated {
                ScoreCard(label: "Ranking:",
                          value: "\(movie.ranking)",
                          total: model.totalCount.map(String.init) ?? "–",
                          score: movie.score)
            } else {
                Text("Not Yet Reviewed")
                    .font(.title3.bold())
                    .foregroundStyle(.appAccent)
                    .padding(12)
                    .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
}

/// A titled paragraph on a card (Plot, Review).
struct TextBlock: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.appAccent)
            Text(text)
                .foregroundStyle(.appLight)
        }
        .card()
    }
}

#if DEBUG
#Preview {
    let heat = Movie.fixture(
        title: "Heat", score: 92, universe: "", genre: "Crime", genre2: "Thriller", studio: "Warner Bros.",
        year: 1995, review: "A masterpiece of the genre.", ranking: 12, daniApproved: true,
        plot: "A group of high-end professional thieves start to feel the heat from the LAPD.",
        cast: [CastMember(name: "Al Pacino", character: "Lt. Vincent Hanna", tmdbID: 1158),
               CastMember(name: "Robert De Niro", character: "Neil McCauley", tmdbID: 380),
               CastMember(name: "Val Kilmer", character: "Chris Shiherlis", tmdbID: 5576)],
        directors: ["Michael Mann"], runtime: 170,
        provider: Providers(link: "", rent: [.fixture(id: 2, name: "Apple TV")], flatrate: [.fixture(id: 8, name: "Netflix")], buy: [], ads: [], free: []),
        tmdbID: 949, rottenTomatoes: "87%", imdb: "8.3/10", metacritic: "76/100"
    )
    let ratings = StubRatingsService(onMovie: { _ in heat }, onCount: { 1204 })
    NavigationStack {
        MovieDetailView(repository: MovieRepository(ratings: ratings, tmdb: StubTMDBService()), tmdbID: 949)
            .appDestinations()
    }
    .environment(AppEnvironment.preview(ratings: ratings))
    .preferredColorScheme(.dark)
}
#endif
