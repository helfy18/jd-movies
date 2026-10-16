import Foundation

/// A titled poster row on the home screen with the grid filter its "View All" opens.
nonisolated struct HomeRow: Hashable, Sendable, Identifiable {
    let title: String
    let movies: [PosterMovie]
    let query: MovieListQuery

    var id: String { title }
}

nonisolated enum HomeRows {
    static let rowLimit = 20

    /// November 1st through December 31st.
    static func isChristmasSeason(_ date: Date, calendar: Calendar = .current) -> Bool {
        calendar.component(.month, from: date) >= 11
    }

    /// October only.
    static func isHalloweenSeason(_ date: Date, calendar: Calendar = .current) -> Bool {
        calendar.component(.month, from: date) == 10
    }

    /// Theatre listings: rated movies keep their score, the rest show as unrated.
    /// Unrated movies without a poster are dropped.
    static func withRatings(_ tmdbMovies: [TMDBMovie], rated: [Int: Movie]) -> [PosterMovie] {
        tmdbMovies.compactMap { movie in
            if let match = rated[movie.id] { return PosterMovie(match) }
            guard let path = movie.posterPath, !path.isEmpty else { return nil }
            return PosterMovie(unrated: movie)
        }
    }

    /// The catalogue arrives ranked, so the first matches of each test are the best.
    static func build(catalogue: [Movie], today: Date, calendar: Calendar = .current) -> [HomeRow] {
        guard !catalogue.isEmpty else { return [] }

        func top(_ test: (Movie) -> Bool) -> [PosterMovie] {
            catalogue.lazy.filter(test).prefix(rowLimit).map(PosterMovie.init)
        }

        let latestYear = catalogue.map(\.year).max() ?? 0
        let lastYear = latestYear - 1
        var rows: [HomeRow] = []

        if isChristmasSeason(today, calendar: calendar) {
            rows.append(HomeRow(title: "Best Christmas Movies",
                                movies: top { $0.holiday == "Christmas" },
                                query: MovieListQuery(holiday: ["Christmas"])))
        }
        if isHalloweenSeason(today, calendar: calendar) {
            rows.append(HomeRow(title: "Best Halloween Movies",
                                movies: top { $0.holiday == "Halloween" },
                                query: MovieListQuery(holiday: ["Halloween"])))
            rows.append(HomeRow(title: "Spooky Season",
                                movies: top { $0.genre == "Horror" },
                                query: MovieListQuery(genre: ["Horror"])))
        }

        let freeMovies = top { $0.provider.hasFreeOption }
        if !freeMovies.isEmpty {
            rows.append(HomeRow(title: "Free to Watch", movies: freeMovies, query: MovieListQuery(free: true)))
        }
        let daniMovies = top(\.daniApproved)
        if !daniMovies.isEmpty {
            rows.append(HomeRow(title: "Dani Approved", movies: daniMovies, query: MovieListQuery(daniApproved: true)))
        }

        rows += [
            HomeRow(title: "Best of This Year",
                    movies: top { $0.year == latestYear },
                    query: MovieListQuery(year: [String(latestYear)])),
            HomeRow(title: "Best of Last Year",
                    movies: top { $0.year == lastYear },
                    query: MovieListQuery(year: [String(lastYear)])),
            HomeRow(title: "Best of the 80's",
                    movies: top { (1980...1989).contains($0.year) },
                    query: .decade(startingAt: 1980)),
            HomeRow(title: "Best of the 90's",
                    movies: top { (1990...1999).contains($0.year) },
                    query: .decade(startingAt: 1990)),
            HomeRow(title: "Best of DC",
                    movies: top { $0.universe == "DC" },
                    query: MovieListQuery(universe: ["DC"])),
            HomeRow(title: "Best of Marvel",
                    movies: top { $0.universe == "Marvel" },
                    query: MovieListQuery(universe: ["Marvel"])),
        ]
        return rows
    }
}
