import SwiftUI

/// The "Ratings" screen: every rated movie, searchable and filterable.
struct MovieGridView: View {
    @State private var model: MovieGridViewModel
    @State private var showFilters = false

    /// Minimum tile width chosen so three columns fit on every iPhone.
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 12)]

    init(repository: MovieRepository, query: MovieListQuery = .all) {
        _model = State(initialValue: MovieGridViewModel(repository: repository, query: query))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                summary
                peopleRow
                content
            }
            .padding(.vertical)
        }
        .screenBackground()
        .searchable(text: $model.searchText, prompt: "Title, actor, director…")
        .navigationTitle("Ratings")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                filterButton
            }
        }
        .sheet(isPresented: $showFilters) {
            filtersSheet
        }
        .task { await model.load() }
    }

    @ViewBuilder
    private var summary: some View {
        if model.movies.value != nil {
            let shown = model.displayedMovies.count
            let total = model.totalCount
            Group {
                if model.query.isEmpty && shown == total {
                    Text("^[\(total) movie](inflect: true)")
                } else if model.query.isEmpty {
                    Text("\(shown) of ^[\(total) movie](inflect: true)")
                } else {
                    Text("Filtered · \(shown) of ^[\(total) movie](inflect: true)")
                }
            }
            .font(.footnote)
            .foregroundStyle(.appMuted)
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var peopleRow: some View {
        let people = model.peopleMatches
        if !people.isEmpty {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    Text("People:")
                        .foregroundStyle(.appLight)
                    ForEach(people) { person in
                        ChipLink(text: "\(person.name) (\(person.count))", route: .person(person.name))
                    }
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.movies {
        case .idle, .loading:
            LoadingView()
        case .failed:
            ErrorView(message: "Couldn't load the movie list.") {
                await model.retry()
            }
        case .loaded:
            let movies = model.displayedMovies
            if movies.isEmpty {
                MessageView("No movies match.")
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(movies) { movie in
                        PosterLink(movie: movie, width: nil)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var filterButton: some View {
        Button {
            showFilters = true
        } label: {
            Label("Filters", systemImage: model.query.isEmpty
                  ? "line.3.horizontal.decrease.circle"
                  : "line.3.horizontal.decrease.circle.fill")
        }
        .disabled(model.filterTypes.value == nil)
    }

    @ViewBuilder
    private var filtersSheet: some View {
        if let options = model.filterTypes.value {
            FiltersSheet(options: options, query: model.query) { query in
                Task { await model.apply(query) }
            }
        }
    }
}

#if DEBUG
#Preview {
    let ratings = StubRatingsService(
        onCompactList: { _ in (1...30).map { CompactMovie.fixture(title: "Movie \($0)", score: 100 - $0 * 2, tmdbID: $0, cast: CastMember.names("Actor \($0 % 4)")) } },
        onFilterTypes: { .fixture() }
    )
    NavigationStack {
        MovieGridView(repository: MovieRepository(ratings: ratings, tmdb: StubTMDBService()))
            .appDestinations()
    }
    .environment(AppEnvironment.preview(ratings: ratings))
    .preferredColorScheme(.dark)
}
#endif
