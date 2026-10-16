import Foundation

nonisolated struct Rating: Codable, Hashable, Sendable {
    var source: String
    var value: String
}

nonisolated struct ProviderInfo: Codable, Hashable, Sendable, Identifiable {
    var logoPath: String
    var providerID: Int
    var providerName: String
    var displayPriority: Int

    var id: Int { providerID }
    var logoURL: URL? { TMDBImage.url(path: logoPath, size: .w154) }

    enum CodingKeys: String, CodingKey {
        case logoPath = "logo_path"
        case providerID = "provider_id"
        case providerName = "provider_name"
        case displayPriority = "display_priority"
    }
}

/// Where a movie can be streamed, rented or bought (sourced from JustWatch via TMDB).
nonisolated struct Providers: Hashable, Sendable {
    var link: String
    var rent: [ProviderInfo]
    var flatrate: [ProviderInfo]
    var buy: [ProviderInfo]
    var ads: [ProviderInfo]
    var free: [ProviderInfo]

    static let none = Providers(link: "", rent: [], flatrate: [], buy: [], ads: [], free: [])

    /// Free and ad-supported providers, de-duplicated by provider id.
    var freeToWatch: [ProviderInfo] {
        var seen = Set<Int>()
        return (free + ads).filter { seen.insert($0.providerID).inserted }
    }

    var hasFreeOption: Bool { !free.isEmpty || !ads.isEmpty }

    enum CodingKeys: String, CodingKey {
        case link, rent, flatrate, buy, ads, free
    }
}

nonisolated extension Providers: Codable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        link = try container.decodeString(forKey: .link)
        rent = try container.decodeArray(forKey: .rent)
        flatrate = try container.decodeArray(forKey: .flatrate)
        buy = try container.decodeArray(forKey: .buy)
        ads = try container.decodeArray(forKey: .ads)
        free = try container.decodeArray(forKey: .free)
    }
}

/// A fully rated movie as served by `/movies/get`, `/movies/list` and friends.
nonisolated struct Movie: Hashable, Sendable, Identifiable {
    /// Score used for movies that are not in the ratings catalogue (theatre listings, TMDB fallback).
    static let unratedScore = -1

    var title: String
    var score: Int
    var universe: String
    var subUniverse: String
    var genre: String
    var genre2: String
    var holiday: String
    var exclusive: String
    var studio: String
    var year: Int
    var review: String
    var ranking: Int
    var daniApproved: Bool
    var plot: String
    var poster: String
    var cast: [String]
    var directors: [String]
    var ratings: [Rating]
    var boxOffice: String
    var rated: String
    var runtime: Int
    var provider: Providers
    var budget: String
    var tmdbID: Int
    var recommendations: [Int]
    var rottenTomatoes: String
    var imdb: String
    var metacritic: String
    var trailer: String

    var id: Int { tmdbID }
    var isRated: Bool { score != Movie.unratedScore }
    var genres: [String] { [genre, genre2].filter { !$0.isEmpty } }
    /// The sub-universe when set, otherwise the universe (used for franchise stats).
    var franchise: String? { subUniverse.nonEmpty ?? universe.nonEmpty }
    var trailerURL: URL? { URL(string: trailer) }

    /// The YouTube video id from an embed URL like `https://www.youtube.com/embed/KEY`.
    var trailerVideoID: String? {
        guard let url = trailerURL, url.host()?.hasSuffix("youtube.com") == true,
              url.pathComponents.contains("embed") else { return nil }
        return url.lastPathComponent.nonEmpty
    }

    /// The regular YouTube watch page for the trailer, for opening outside the app.
    var trailerWatchURL: URL? {
        trailerVideoID.flatMap { URL(string: "https://www.youtube.com/watch?v=\($0)") }
    }

    func posterURL(_ size: TMDBImage.Size = .w500) -> URL? {
        TMDBImage.resized(poster, to: size)
    }

    enum CodingKeys: String, CodingKey {
        case title = "movie"
        case score = "jh_score"
        case universe
        case subUniverse = "sub_universe"
        case genre
        case genre2 = "genre_2"
        case holiday, exclusive, studio, year, review, ranking
        case daniApproved = "dani_approved"
        case plot, poster, cast, directors, ratings
        case boxOffice = "boxoffice"
        case rated, runtime, provider, budget
        case tmdbID = "tmdbid"
        case recommendations
        case rottenTomatoes = "rottentomatoes"
        case imdb, metacritic, trailer
    }
}

nonisolated extension Movie: Codable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeString(forKey: .title)
        score = try container.decodeInt(forKey: .score)
        universe = try container.decodeString(forKey: .universe)
        subUniverse = try container.decodeString(forKey: .subUniverse)
        genre = try container.decodeString(forKey: .genre)
        genre2 = try container.decodeString(forKey: .genre2)
        holiday = try container.decodeString(forKey: .holiday)
        exclusive = try container.decodeString(forKey: .exclusive)
        studio = try container.decodeString(forKey: .studio)
        year = try container.decodeInt(forKey: .year)
        review = try container.decodeString(forKey: .review)
        ranking = try container.decodeInt(forKey: .ranking)
        daniApproved = try container.decodeBool(forKey: .daniApproved)
        plot = try container.decodeString(forKey: .plot)
        poster = try container.decodeString(forKey: .poster)
        cast = try container.decodeArray(forKey: .cast)
        directors = try container.decodeArray(forKey: .directors)
        ratings = try container.decodeArray(forKey: .ratings)
        boxOffice = try container.decodeString(forKey: .boxOffice)
        rated = try container.decodeString(forKey: .rated)
        runtime = try container.decodeInt(forKey: .runtime)
        provider = try container.decodeIfPresent(Providers.self, forKey: .provider) ?? .none
        budget = try container.decodeString(forKey: .budget)
        tmdbID = try container.decode(Int.self, forKey: .tmdbID)
        recommendations = try container.decodeArray(forKey: .recommendations)
        rottenTomatoes = try container.decodeString(forKey: .rottenTomatoes)
        imdb = try container.decodeString(forKey: .imdb)
        metacritic = try container.decodeString(forKey: .metacritic)
        trailer = try container.decodeString(forKey: .trailer)
    }
}

/// The `view=compact` projection: only the fields the grid renders and searches.
nonisolated struct CompactMovie: Hashable, Sendable, Identifiable {
    var title: String
    var score: Int
    var poster: String
    var tmdbID: Int
    var daniApproved: Bool
    var cast: [String]
    var directors: [String]
    var universe: String
    var subUniverse: String
    var studio: String
    var year: Int

    var id: Int { tmdbID }

    enum CodingKeys: String, CodingKey {
        case title = "movie"
        case score = "jh_score"
        case poster
        case tmdbID = "tmdbid"
        case daniApproved = "dani_approved"
        case cast, directors, universe
        case subUniverse = "sub_universe"
        case studio, year
    }
}

nonisolated extension CompactMovie: Codable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeString(forKey: .title)
        score = try container.decodeInt(forKey: .score)
        poster = try container.decodeString(forKey: .poster)
        tmdbID = try container.decode(Int.self, forKey: .tmdbID)
        daniApproved = try container.decodeBool(forKey: .daniApproved)
        cast = try container.decodeArray(forKey: .cast)
        directors = try container.decodeArray(forKey: .directors)
        universe = try container.decodeString(forKey: .universe)
        subUniverse = try container.decodeString(forKey: .subUniverse)
        studio = try container.decodeString(forKey: .studio)
        year = try container.decodeInt(forKey: .year)
    }
}

/// The minimal shape a poster tile needs. Built from any of the movie types.
nonisolated struct PosterMovie: Hashable, Sendable, Identifiable {
    var title: String
    var score: Int
    var poster: String
    var tmdbID: Int
    var daniApproved: Bool

    var id: Int { tmdbID }
    var isRated: Bool { score != Movie.unratedScore }
    var scoreLabel: String { isRated ? "\(score)/100" : "N/A" }

    init(title: String, score: Int, poster: String, tmdbID: Int, daniApproved: Bool) {
        self.title = title
        self.score = score
        self.poster = poster
        self.tmdbID = tmdbID
        self.daniApproved = daniApproved
    }

    init(_ movie: Movie) {
        self.init(title: movie.title, score: movie.score, poster: movie.poster,
                  tmdbID: movie.tmdbID, daniApproved: movie.daniApproved)
    }

    init(_ movie: CompactMovie) {
        self.init(title: movie.title, score: movie.score, poster: movie.poster,
                  tmdbID: movie.tmdbID, daniApproved: movie.daniApproved)
    }

    /// An unrated theatre listing. Renders as "N/A" and the detail page falls back to TMDB data.
    init(unrated movie: TMDBMovie) {
        self.init(title: movie.title, score: Movie.unratedScore,
                  poster: TMDBImage.urlString(path: movie.posterPath, size: .w500),
                  tmdbID: movie.id, daniApproved: false)
    }

    func posterURL(_ size: TMDBImage.Size = .w500) -> URL? {
        TMDBImage.resized(poster, to: size)
    }
}
