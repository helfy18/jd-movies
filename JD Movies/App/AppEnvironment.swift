import Foundation
import Observation

/// Long-lived app services, created once at launch and shared through the SwiftUI environment.
@MainActor
@Observable
final class AppEnvironment {
    let configuration: AppConfiguration
    let repository: MovieRepository
    let imageLoader: ImageLoader

    init(configuration: AppConfiguration, repository: MovieRepository, imageLoader: ImageLoader = ImageLoader()) {
        self.configuration = configuration
        self.repository = repository
        self.imageLoader = imageLoader
    }

    static func live() -> AppEnvironment {
        let configuration = AppConfiguration.fromBundle()
        let ratings = RatingsAPIClient(baseURL: configuration.ratingsBaseURL)
        let tmdb: any TMDBService
        if let key = configuration.tmdbAPIKey {
            tmdb = TMDBAPIClient(apiKey: key)
        } else {
            tmdb = UnavailableTMDBService()
        }
        return AppEnvironment(configuration: configuration,
                              repository: MovieRepository(ratings: ratings, tmdb: tmdb))
    }

    #if DEBUG
    /// Offline environment for SwiftUI previews.
    static func preview(ratings: StubRatingsService = StubRatingsService(),
                        tmdb: StubTMDBService = StubTMDBService()) -> AppEnvironment {
        AppEnvironment(configuration: AppConfiguration(ratingsBaseURL: AppConfiguration.defaultRatingsBaseURL,
                                                       siteBaseURL: AppConfiguration.defaultSiteBaseURL,
                                                       tmdbAPIKey: nil),
                       repository: MovieRepository(ratings: ratings, tmdb: tmdb))
    }
    #endif
}
