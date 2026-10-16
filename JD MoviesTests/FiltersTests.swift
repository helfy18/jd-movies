import Foundation
import Testing
@testable import JD_Movies

struct FiltersTests {
    @Test func draftRoundTripsAQuery() {
        let draft = FilterDraft(query: MovieListQuery(genre: ["Horror"], free: true), runtimeBounds: 60...240)
        #expect(draft.query == MovieListQuery(genre: ["Horror"], free: true))
    }

    @Test func fullRangesAreOmittedAndNarrowedRangesKept() {
        var draft = FilterDraft(runtimeBounds: 60...240)
        #expect(draft.query.runtime == nil)
        #expect(draft.query.rating == nil)
        draft.score = 80...100
        draft.runtime = 90...240
        #expect(draft.query.rating == 80...100)
        #expect(draft.query.runtime == 90...240)
    }

    @Test func resetClearsSelectionsButKeepsBounds() {
        var draft = FilterDraft(query: MovieListQuery(genre: ["Horror"], daniApproved: true), runtimeBounds: 60...240)
        draft.reset()
        #expect(draft.query.isEmpty)
        #expect(draft.runtimeBounds == 60...240)
    }

    @Test func genreSectionsSplitPopularFromTheRest() {
        let genres = (0..<14).map { FilterCount(fieldValue: "G\($0)", totalCount: 100 - $0) }
        let sections = FilterOptions.genres(genres)
        #expect(sections.map(\.title) == ["Popular Genres", "More Genres"])
        #expect(sections[0].options.count == FilterOptions.popularGenreCount)
        #expect(sections[1].options.count == 4)
    }

    @Test func universeSectionsGroupSubUniverses() {
        let sections = FilterOptions.universes(FilterTypes.fixture().universes)
        #expect(sections.map(\.title) == ["Marvel", "Other"])
        #expect(sections.first?.options.map(\.value) == ["MCU", "X-Men", "Marvel"])
        #expect(sections.first?.options.last?.label == "All Marvel")
        #expect(sections.last?.options.map(\.value) == ["John Wick"])
    }

    @Test func yearsAndDecadesAreNewestFirst() {
        let years = FilterTypes.fixture().year
        #expect(FilterOptions.years(years) == ["2024", "2023", "1999", "1985"])
        #expect(FilterOptions.decades(fromYears: years) == ["2020-2029", "1990-1999", "1980-1989"])
    }

    @Test func providerNamesResolveFromIDs() {
        let providers = FilterTypes.fixture().provider
        #expect(FilterOptions.providerName(for: "337", in: providers) == "Disney Plus")
        #expect(FilterOptions.providerName(for: "1", in: providers) == "1")
    }

    @Test func queryItemsMatchTheWebsite() {
        var query = MovieListQuery(genre: ["Horror", "Comedy"], free: true)
        query.runtime = 60...180
        query.rating = 90...100
        let items = query.queryItems.map { "\($0.name)=\($0.value ?? "")" }
        #expect(items == ["genre=Horror", "genre=Comedy", "runtime=60", "runtime=180", "rating=90", "rating=100", "free=true"])
        #expect(query.activeFilterCount == 4)
        #expect(MovieListQuery.all.isEmpty)
    }

    @Test func endpointsAppendPathsAndQueries() throws {
        let base = try #require(URL(string: "https://api.example.com"))
        let list = try Endpoint.url(base: base, path: "/movies/list", query: MovieListQuery(genre: ["Horror"]).queryItems)
        #expect(list.absoluteString == "https://api.example.com/movies/list?genre=Horror")
        #expect(try Endpoint.url(base: base, path: "/movies/count").absoluteString == "https://api.example.com/movies/count")
    }
}
