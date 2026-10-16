import Foundation
import Testing
@testable import JD_Movies

struct ProviderSearchTests {
    private let fallback = "https://www.justwatch.com/title"

    @Test func buildsASearchURLForAKnownProvider() {
        #expect(ProviderSearch.url(providerID: 8, title: "The Matrix", fallback: fallback)
                == "https://www.netflix.com/search?q=The%20Matrix")
    }

    @Test func encodesSpecialCharacters() {
        #expect(ProviderSearch.url(providerID: 192, title: "Fast & Furious", fallback: fallback)
                == "https://www.youtube.com/results?search_query=Fast%20%26%20Furious")
    }

    @Test func ignoresTheTitleForProvidersWithoutSearch() {
        #expect(ProviderSearch.url(providerID: 337, title: "Frozen", fallback: fallback)
                == "https://www.disneyplus.com/browse/search")
    }

    @Test func fallsBackForUnknownProviders() {
        #expect(ProviderSearch.url(providerID: 999_999, title: "The Matrix", fallback: fallback) == fallback)
    }
}
