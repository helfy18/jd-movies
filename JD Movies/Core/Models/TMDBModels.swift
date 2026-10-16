import Foundation

/// A movie from TMDB's now-playing / upcoming lists.
nonisolated struct TMDBMovie: Decodable, Hashable, Sendable, Identifiable {
    var id: Int
    var title: String
    var posterPath: String?
    var releaseDate: String?

    init(id: Int, title: String, posterPath: String?, releaseDate: String? = nil) {
        self.id = id
        self.title = title
        self.posterPath = posterPath
        self.releaseDate = releaseDate
    }

    enum CodingKeys: String, CodingKey {
        case id, title
        case posterPath = "poster_path"
        case releaseDate = "release_date"
    }
}

nonisolated struct TMDBPage<Item: Decodable & Hashable & Sendable>: Decodable, Hashable, Sendable {
    var results: [Item]
}

nonisolated struct TMDBGenre: Decodable, Hashable, Sendable {
    var id: Int
    var name: String
}

nonisolated struct TMDBCastMember: Decodable, Hashable, Sendable {
    var name: String
}

nonisolated struct TMDBCrewMember: Decodable, Hashable, Sendable {
    var name: String
    var job: String?
}

nonisolated struct TMDBCredits: Hashable, Sendable {
    var cast: [TMDBCastMember]
    var crew: [TMDBCrewMember]

    enum CodingKeys: String, CodingKey {
        case cast, crew
    }
}

nonisolated extension TMDBCredits: Decodable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cast = try container.decodeArray(forKey: .cast)
        crew = try container.decodeArray(forKey: .crew)
    }
}

nonisolated struct TMDBVideo: Decodable, Hashable, Sendable {
    var key: String
    var site: String
    var type: String
}

nonisolated struct TMDBProviderCountry: Hashable, Sendable {
    var link: String?
    var flatrate: [ProviderInfo]
    var rent: [ProviderInfo]
    var buy: [ProviderInfo]
    var ads: [ProviderInfo]
    var free: [ProviderInfo]

    enum CodingKeys: String, CodingKey {
        case link, flatrate, rent, buy, ads, free
    }
}

nonisolated extension TMDBProviderCountry: Decodable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        link = try container.decodeIfPresent(String.self, forKey: .link)
        flatrate = try container.decodeArray(forKey: .flatrate)
        rent = try container.decodeArray(forKey: .rent)
        buy = try container.decodeArray(forKey: .buy)
        ads = try container.decodeArray(forKey: .ads)
        free = try container.decodeArray(forKey: .free)
    }
}

nonisolated struct TMDBWatchProviders: Decodable, Hashable, Sendable {
    var results: [String: TMDBProviderCountry]
}

nonisolated struct TMDBReleaseDate: Decodable, Hashable, Sendable {
    var certification: String?
}

nonisolated struct TMDBCountryReleases: Hashable, Sendable {
    var countryCode: String
    var releaseDates: [TMDBReleaseDate]

    enum CodingKeys: String, CodingKey {
        case countryCode = "iso_3166_1"
        case releaseDates = "release_dates"
    }
}

nonisolated extension TMDBCountryReleases: Decodable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        countryCode = try container.decodeString(forKey: .countryCode)
        releaseDates = try container.decodeArray(forKey: .releaseDates)
    }
}

nonisolated struct TMDBIDOnly: Decodable, Hashable, Sendable {
    var id: Int
}

/// `/movie/{id}` with credits, videos, watch providers, release dates and recommendations appended.
nonisolated struct TMDBMovieDetail: Hashable, Sendable {
    var adult: Bool
    var budget: Int?
    var genres: [TMDBGenre]
    var id: Int
    var overview: String?
    var posterPath: String?
    var releaseDate: String?
    var revenue: Int?
    var runtime: Int?
    var title: String
    var credits: TMDBCredits?
    var videos: TMDBPage<TMDBVideo>?
    var watchProviders: TMDBWatchProviders?
    var releaseDates: TMDBPage<TMDBCountryReleases>?
    var recommendations: TMDBPage<TMDBIDOnly>?

    enum CodingKeys: String, CodingKey {
        case adult, budget, genres, id, overview
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case revenue, runtime, title, credits, videos
        case watchProviders = "watch/providers"
        case releaseDates = "release_dates"
        case recommendations
    }
}

nonisolated extension TMDBMovieDetail: Decodable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        adult = try container.decodeBool(forKey: .adult)
        budget = try container.decodeIfPresent(Int.self, forKey: .budget)
        genres = try container.decodeArray(forKey: .genres)
        id = try container.decode(Int.self, forKey: .id)
        overview = try container.decodeIfPresent(String.self, forKey: .overview)
        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
        revenue = try container.decodeIfPresent(Int.self, forKey: .revenue)
        runtime = try container.decodeIfPresent(Int.self, forKey: .runtime)
        title = try container.decodeString(forKey: .title)
        credits = try container.decodeIfPresent(TMDBCredits.self, forKey: .credits)
        videos = try container.decodeIfPresent(TMDBPage<TMDBVideo>.self, forKey: .videos)
        watchProviders = try container.decodeIfPresent(TMDBWatchProviders.self, forKey: .watchProviders)
        releaseDates = try container.decodeIfPresent(TMDBPage<TMDBCountryReleases>.self, forKey: .releaseDates)
        recommendations = try container.decodeIfPresent(TMDBPage<TMDBIDOnly>.self, forKey: .recommendations)
    }
}

nonisolated struct TMDBPersonResult: Decodable, Hashable, Sendable {
    var id: Int
    var name: String
}

nonisolated struct TMDBPerson: Decodable, Hashable, Sendable, Identifiable {
    var id: Int
    var name: String
    var biography: String?
    var profilePath: String?

    var photoURL: URL? { TMDBImage.url(path: profilePath, size: .w342) }

    init(id: Int, name: String, biography: String?, profilePath: String?) {
        self.id = id
        self.name = name
        self.biography = biography
        self.profilePath = profilePath
    }

    enum CodingKeys: String, CodingKey {
        case id, name, biography
        case profilePath = "profile_path"
    }
}

nonisolated extension Providers {
    /// Providers for one country from TMDB, or none when the country is missing.
    init(country: TMDBProviderCountry?) {
        self.init(link: country?.link ?? "",
                  rent: country?.rent ?? [],
                  flatrate: country?.flatrate ?? [],
                  buy: country?.buy ?? [],
                  ads: country?.ads ?? [],
                  free: country?.free ?? [])
    }
}

nonisolated extension Movie {
    private static let tmdbCastLimit = 20

    /// A movie that is not in the ratings catalogue, built straight from TMDB.
    /// Returns `nil` for adult titles, which the site never shows.
    init?(unrated detail: TMDBMovieDetail) {
        guard !detail.adult else { return nil }
        let usReleases = detail.releaseDates?.results.first { $0.countryCode == "US" }
        let certification = usReleases?.releaseDates
            .compactMap { $0.certification?.nonEmpty }
            .first
        let trailer = detail.videos?.results.first { $0.site == "YouTube" && $0.type == "Trailer" }
        let genres = detail.genres.map(\.name)

        self.init(
            title: detail.title,
            score: Movie.unratedScore,
            universe: "",
            subUniverse: "",
            genre: genres.first ?? "",
            genre2: genres.dropFirst().first ?? "",
            holiday: "",
            exclusive: "",
            studio: "",
            year: Int((detail.releaseDate ?? "").prefix(4)) ?? 0,
            review: "",
            ranking: 0,
            daniApproved: false,
            plot: detail.overview ?? "",
            poster: TMDBImage.urlString(path: detail.posterPath, size: .w500),
            cast: (detail.credits?.cast ?? []).prefix(Movie.tmdbCastLimit).map(\.name),
            directors: (detail.credits?.crew ?? []).filter { $0.job == "Director" }.map(\.name),
            ratings: [],
            boxOffice: Movie.groupedNumber(detail.revenue ?? 0),
            rated: certification ?? "",
            runtime: detail.runtime ?? 0,
            provider: Providers(country: detail.watchProviders?.results["US"]),
            budget: Movie.groupedNumber(detail.budget ?? 0),
            tmdbID: detail.id,
            recommendations: detail.recommendations?.results.map(\.id) ?? [],
            rottenTomatoes: "",
            imdb: "",
            metacritic: "",
            trailer: trailer.map { "https://www.youtube.com/embed/\($0.key)" } ?? ""
        )
    }

    /// Matches the catalogue's stored money strings, e.g. "1,234,567".
    static func groupedNumber(_ value: Int) -> String {
        value.formatted(.number.grouping(.automatic).locale(Locale(identifier: "en_US")))
    }
}
