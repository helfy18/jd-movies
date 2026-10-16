import SwiftUI

/// The label/value table from the website's `InfoTable`, with tappable chips.
struct MovieInfoSection: View {
    let movie: Movie

    @State private var castExpanded = false
    private static let collapsedCastCount = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            row("Title") {
                Text(movie.title)
            }
            if movie.isRated {
                row("Score") {
                    Text("\(movie.score)/100")
                        .bold()
                        .foregroundStyle(Color.score(movie.score))
                }
            }
            chipRow("Universe", values: movie.universe.nonEmpty.map { [$0] } ?? []) {
                .grid(MovieListQuery(universe: [$0]))
            }
            chipRow("Sub Universe", values: movie.subUniverse.nonEmpty.map { [$0] } ?? []) {
                .grid(MovieListQuery(universe: [$0]))
            }
            chipRow(movie.genres.count > 1 ? "Genres" : "Genre", values: movie.genres) {
                .grid(MovieListQuery(genre: [$0]))
            }
            chipRow("Exclusive", values: movie.exclusive.nonEmpty.map { [$0] } ?? []) {
                .grid(MovieListQuery(exclusive: [$0]))
            }
            chipRow("Holiday", values: movie.holiday.nonEmpty.map { [$0] } ?? []) {
                .grid(MovieListQuery(holiday: [$0]))
            }
            chipRow("Year", values: movie.year > 0 ? [String(movie.year)] : []) {
                .grid(MovieListQuery(year: [$0]))
            }
            if let rated = movie.rated.nonEmpty {
                row("MPA Rating") { Text(rated) }
            }
            if movie.runtime > 0 {
                row("Runtime") { Text("\(movie.runtime) min") }
            }
            if let budget = money(movie.budget) {
                row("Budget") { Text(budget) }
            }
            if let boxOffice = money(movie.boxOffice) {
                row("Box Office") { Text(boxOffice) }
            }
            castRow
            chipRow(movie.directors.count > 1 ? "Directors" : "Director", values: movie.directors) {
                .person($0)
            }
            chipRow("Studio", values: movie.studio.nonEmpty.map { [$0] } ?? []) {
                .grid(MovieListQuery(studio: [$0]))
            }
        }
        .card()
    }

    @ViewBuilder
    private var castRow: some View {
        if !movie.cast.isEmpty {
            let collapsible = movie.cast.count > Self.collapsedCastCount
            let visible = castExpanded || !collapsible ? movie.cast : Array(movie.cast.prefix(Self.collapsedCastCount))
            row("Actors") {
                VStack(alignment: .leading, spacing: 6) {
                    FlowLayout {
                        ForEach(visible, id: \.self) { name in
                            ChipLink(text: name, route: .person(name))
                        }
                    }
                    if collapsible {
                        Button {
                            withAnimation { castExpanded.toggle() }
                        } label: {
                            Label(castExpanded ? "Show less" : "Show all \(movie.cast.count)",
                                  systemImage: castExpanded ? "chevron.up" : "chevron.down")
                                .font(.footnote)
                                .foregroundStyle(.appMuted)
                        }
                    }
                }
            }
        }
    }

    private func row<Value: View>(_ label: String, @ViewBuilder value: () -> Value) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .foregroundStyle(.appAccent)
                .frame(width: 96, alignment: .leading)
            value()
                .foregroundStyle(.appLight)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func chipRow(_ label: String, values: [String], route: @escaping (String) -> Route) -> some View {
        if !values.isEmpty {
            row(label) {
                FlowLayout {
                    ForEach(values, id: \.self) { value in
                        ChipLink(text: value, route: route(value))
                    }
                }
            }
        }
    }

    /// The API stores money as pre-formatted strings; "0" and "" mean unknown.
    private func money(_ value: String) -> String? {
        guard !value.isEmpty, value != "0" else { return nil }
        return "$" + value
    }
}
