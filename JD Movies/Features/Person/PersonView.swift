import SwiftUI

struct PersonView: View {
    @State private var model: PersonViewModel

    init(repository: MovieRepository, name: String) {
        _model = State(initialValue: PersonViewModel(repository: repository, name: name))
    }

    var body: some View {
        ScrollView {
            switch model.state {
            case .idle, .loading:
                LoadingView()
            case .failed:
                ErrorView(message: "Couldn't load this person.") {
                    await model.load(force: true)
                }
            case .loaded(let filmography):
                content(filmography)
            }
        }
        .screenBackground()
        .navigationTitle(model.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load() }
    }

    private func content(_ filmography: PersonFilmography) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            PersonHeader(filmography: filmography, person: model.person)
                .padding(.horizontal)
            if filmography.isEmpty {
                MessageView("No rated movies for \(model.name).")
            }
            if !filmography.directed.isEmpty {
                PosterRow(title: "Directed (\(filmography.directed.count))", movies: filmography.directed)
            }
            if !filmography.actedIn.isEmpty {
                PosterRow(title: "Acted In (\(filmography.actedIn.count))", movies: filmography.actedIn)
            }
        }
        .padding(.vertical)
    }
}

private struct PersonHeader: View {
    let filmography: PersonFilmography
    let person: TMDBPerson?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                photo
                VStack(alignment: .leading, spacing: 6) {
                    Text(filmography.name)
                        .font(.title2.bold())
                        .foregroundStyle(.appAccent)
                    if let best = filmography.best {
                        summaryLine
                        HStack(spacing: 4) {
                            Text("Best:")
                            MovieScoreLink(movie: best)
                        }
                        if let worst = filmography.worst {
                            HStack(spacing: 4) {
                                Text("Worst:")
                                MovieScoreLink(movie: worst)
                            }
                        }
                    }
                }
                .foregroundStyle(.appLight)
            }
            if !filmography.scores.isEmpty {
                ScoreBarsChart(scores: filmography.scores)
            }
            if let biography = person?.biography?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty {
                BiographyText(text: biography)
            }
        }
        .card()
    }

    @ViewBuilder
    private var photo: some View {
        Group {
            if let url = person?.photoURL {
                RemoteImage(url: url, contentMode: .fill) {
                    PosterPlaceholder()
                }
            } else {
                Rectangle()
                    .fill(Color.appMuted.opacity(0.25))
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.appMuted)
                    }
            }
        }
        .frame(width: 110, height: 165)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var summaryLine: Text {
        let average = Text(filmography.averageScore, format: .number.precision(.fractionLength(2)))
            .bold()
            .foregroundStyle(Color.score(filmography.averageScore))
        if filmography.daniApprovedCount > 0 {
            return Text("^[\(filmography.movieCount) movie](inflect: true) rated · Avg \(average) · \(filmography.daniApprovedCount) Dani approved")
        }
        return Text("^[\(filmography.movieCount) movie](inflect: true) rated · Avg \(average)")
    }
}

/// "Title (92)" with the score coloured, linking to the movie.
private struct MovieScoreLink: View {
    let movie: PosterMovie

    var body: some View {
        NavigationLink(value: Route.movie(movie.tmdbID)) {
            Text("\(Text(movie.title).underline()) \(scoreText)")
                .multilineTextAlignment(.leading)
        }
        .buttonStyle(.plain)
    }

    private var scoreText: Text {
        Text("(\(movie.score))")
            .bold()
            .foregroundStyle(Color.score(movie.score))
    }
}

/// Long biographies start collapsed, like the website.
private struct BiographyText: View {
    let text: String
    @State private var expanded = false
    private static let collapseThreshold = 300

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.appLight)
                .lineLimit(expanded ? nil : 4)
            if text.count > Self.collapseThreshold {
                Button {
                    withAnimation { expanded.toggle() }
                } label: {
                    Label(expanded ? "Show less" : "Show more",
                          systemImage: expanded ? "chevron.up" : "chevron.down")
                        .font(.footnote)
                        .foregroundStyle(.appMuted)
                }
            }
        }
    }
}
