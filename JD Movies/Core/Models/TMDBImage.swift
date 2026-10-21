import Foundation

/// Builds `image.tmdb.org` URLs for posters, profile photos and provider logos.
nonisolated enum TMDBImage {
    nonisolated enum Size: String, Sendable {
        case w154, w185, w342, w500, w780
    }

    private static let base = "https://image.tmdb.org/t/p/"

    static func urlString(path: String?, size: Size) -> String {
        guard let path, !path.isEmpty else { return "" }
        let separator = path.hasPrefix("/") ? "" : "/"
        return base + size.rawValue + separator + path
    }

    static func url(path: String?, size: Size) -> URL? {
        URL(string: urlString(path: path, size: size))
    }

    /// Swaps the size segment of a stored poster URL (the API stores `w500`).
    static func resized(_ posterURL: String, to size: Size) -> URL? {
        guard !posterURL.isEmpty else { return nil }
        let swapped = posterURL.replacingOccurrences(of: "/w500/", with: "/\(size.rawValue)/")
        return URL(string: swapped)
    }
}
