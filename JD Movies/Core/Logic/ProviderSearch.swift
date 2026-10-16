import Foundation

/// Deep links from a provider logo to that service's search for the movie.
nonisolated enum ProviderSearch {
    private typealias SearchURL = @Sendable (String) -> String

    /// Mirrors JavaScript's `encodeURIComponent`.
    private static let uriComponentAllowed: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.insert(charactersIn: "-_.!~*'()")
        return set
    }()

    static func encodeURIComponent(_ text: String) -> String {
        text.addingPercentEncoding(withAllowedCharacters: uriComponentAllowed) ?? text
    }

    private static let appleTV: SearchURL = { "https://tv.apple.com/ca/search?term=\(encodeURIComponent($0))" }
    private static let amazon: SearchURL = { "https://www.primevideo.com/region/na/search?phrase=\(encodeURIComponent($0))" }
    private static let youtube: SearchURL = { "https://www.youtube.com/results?search_query=\(encodeURIComponent($0))" }
    private static let googlePlay: SearchURL = { "https://play.google.com/store/search?q=\(encodeURIComponent($0))&c=movies" }
    private static let cosmogo: SearchURL = { "https://www.cosmogo.com/#!/search/\(encodeURIComponent($0))" }
    private static let crave: SearchURL = { "https://www.crave.ca/en/search/\(encodeURIComponent($0))" }
    private static let netflix: SearchURL = { "https://www.netflix.com/search?q=\(encodeURIComponent($0))" }
    private static let paramount: SearchURL = { _ in "https://www.paramountplus.com/search/" }
    private static let plex: SearchURL = { _ in "https://watch.plex.tv/search" }
    private static let disney: SearchURL = { _ in "https://www.disneyplus.com/browse/search" }

    private static let byProvider: [Int: SearchURL] = [
        2: appleTV, 350: appleTV, 1852: appleTV, 1854: appleTV, 2048: appleTV, 2049: appleTV,
        10: amazon, 119: amazon, 2100: amazon, 201: amazon, 204: amazon, 205: amazon, 528: amazon,
        582: amazon, 588: amazon, 605: amazon, 606: amazon, 705: amazon, 1794: amazon, 1968: amazon,
        2243: amazon, 2358: amazon, 2604: amazon, 2745: amazon,
        192: youtube,
        3: googlePlay,
        140: cosmogo,
        230: crave,
        8: netflix, 1796: netflix,
        531: paramount, 2303: paramount, 2304: paramount,
        538: plex,
        337: disney,
    ]

    /// The provider's search page for the title, or the JustWatch fallback link.
    static func url(providerID: Int, title: String, fallback: String) -> String {
        byProvider[providerID]?(title) ?? fallback
    }
}
