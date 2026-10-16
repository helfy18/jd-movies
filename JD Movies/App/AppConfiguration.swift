import Foundation

/// Values injected at build time through `Config/*.xcconfig` and `Config/Info.plist`.
nonisolated struct AppConfiguration: Sendable {
    let ratingsBaseURL: URL
    let siteBaseURL: URL
    /// `nil` when no TMDB key is configured; TMDB-backed features then degrade gracefully.
    let tmdbAPIKey: String?

    static let defaultRatingsBaseURL = URL(string: "https://rival-rodie-helfy18-8da32b7b.koyeb.app")!
    static let defaultSiteBaseURL = URL(string: "https://jd-movies.netlify.app")!

    static func fromBundle(_ bundle: Bundle = .main) -> AppConfiguration {
        func string(_ key: String) -> String? {
            (bundle.object(forInfoDictionaryKey: key) as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .nonEmpty
        }
        return AppConfiguration(
            ratingsBaseURL: string("JDRatingsAPIBaseURL").flatMap(URL.init(string:)) ?? defaultRatingsBaseURL,
            siteBaseURL: string("JDSiteBaseURL").flatMap(URL.init(string:)) ?? defaultSiteBaseURL,
            tmdbAPIKey: string("JDTMDBAPIKey")
        )
    }

    /// The website page for a movie, used for sharing.
    func movieURL(tmdbID: Int) -> URL {
        siteBaseURL.appending(path: "movie/\(tmdbID)")
    }

    func personURL(name: String) -> URL {
        siteBaseURL.appending(path: "person/\(name)")
    }
}
