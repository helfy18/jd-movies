import SwiftUI

struct HomeView: View {
    @State private var model: HomeViewModel
    @State private var showAbout = false

    init(repository: MovieRepository) {
        _model = State(initialValue: HomeViewModel(repository: repository))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                switch model.state {
                case .idle, .loading:
                    LoadingView()
                case .failed:
                    ErrorView(message: "Couldn't load the home page.") {
                        await model.refresh()
                    }
                case .loaded(let content):
                    rows(for: content)
                }
            }
            .padding(.vertical)
        }
        .screenBackground()
        .refreshable { await model.refresh() }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("About", systemImage: "info.circle") {
                    showAbout = true
                }
            }
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .task { await model.load() }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(.popcorn)
                .resizable()
                .scaledToFit()
                .frame(height: 44)
            Text("JD MOVIES")
                .font(.system(.title, design: .monospaced, weight: .bold))
                .foregroundStyle(.appAccent)
            Image(.popcorn)
                .resizable()
                .scaledToFit()
                .frame(height: 44)
        }
        .frame(maxWidth: .infinity)
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private func rows(for content: HomeViewModel.Content) -> some View {
        if !content.recent.isEmpty {
            PosterRow(title: "Recently Added", movies: content.recent)
        }
        if !content.nowPlaying.isEmpty {
            PosterRow(title: "Now Playing in Theatres", movies: content.nowPlaying)
        }
        if !content.upcoming.isEmpty {
            PosterRow(title: "Coming Soon to Theatres", movies: content.upcoming)
        }
        ForEach(content.rows.filter { !$0.movies.isEmpty }) { row in
            PosterRow(title: row.title, movies: row.movies, viewAll: row.query)
        }
    }
}

#if DEBUG
#Preview {
    let ratings = StubRatingsService(
        onList: { _ in (1...12).map { Movie.fixture(title: "Movie \($0)", score: 60 + $0 * 3, year: 2026, tmdbID: $0) } },
        onMostRecent: { _ in (1...6).map { CompactMovie.fixture(title: "Recent \($0)", tmdbID: 100 + $0) } }
    )
    NavigationStack {
        HomeView(repository: MovieRepository(ratings: ratings, tmdb: StubTMDBService()))
            .appDestinations()
    }
    .environment(AppEnvironment.preview(ratings: ratings))
    .preferredColorScheme(.dark)
}
#endif
