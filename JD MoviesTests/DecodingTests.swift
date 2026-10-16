import Foundation
import Testing
@testable import JD_Movies

struct DecodingTests {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }

    @Test func movieDecodesGoNullsAsEmptyLists() throws {
        let json = """
        {"movie":"Heat","jh_score":92,"universe":"","sub_universe":"","genre":"Crime","genre_2":"","holiday":"","exclusive":"",
         "studio":"Warner Bros.","year":1995,"review":"","ranking":12,"dani_approved":true,"plot":"Cops and robbers.",
         "poster":"https://image.tmdb.org/t/p/w500/heat.jpg","cast":["Al Pacino","Robert De Niro"],"directors":null,"ratings":null,
         "boxoffice":"187,436,818","rated":"R","runtime":170,
         "provider":{"link":"https://www.justwatch.com/us/movie/heat","rent":[{"logo_path":"/a.jpg","provider_id":2,"provider_name":"Apple TV","display_priority":5}],
                     "flatrate":null,"buy":null,"ads":null,"free":null},
         "budget":"60,000,000","tmdbid":949,"recommendations":null,"rottentomatoes":"87%","imdb":"8.3/10","metacritic":"76/100","trailer":""}
        """
        let movie = try decode(Movie.self, json)
        #expect(movie.title == "Heat")
        #expect(movie.ranking == 12)
        #expect(movie.cast == ["Al Pacino", "Robert De Niro"])
        #expect(movie.directors.isEmpty && movie.ratings.isEmpty && movie.recommendations.isEmpty)
        #expect(movie.provider.rent.first?.providerName == "Apple TV")
        #expect(movie.provider.flatrate.isEmpty)
        #expect(movie.posterURL(.w780)?.absoluteString == "https://image.tmdb.org/t/p/w780/heat.jpg")
        #expect(movie.isRated && movie.daniApproved)
    }

    @Test func compactMoviesDecodeFromTheSameShape() throws {
        let json = """
        [{"movie":"Up","jh_score":88,"universe":"","sub_universe":"","genre":"","genre_2":"","holiday":"","exclusive":"","studio":"Pixar",
          "year":2009,"review":"","ranking":0,"dani_approved":false,"plot":"","poster":"p","cast":null,"directors":["Pete Docter"],"ratings":null,
          "boxoffice":"","rated":"","runtime":0,"provider":{"link":"","rent":null,"flatrate":null,"buy":null,"ads":null,"free":null},
          "budget":"","tmdbid":14160,"recommendations":null,"rottentomatoes":"","imdb":"","metacritic":"","trailer":""}]
        """
        let compact = try decode([CompactMovie].self, json)
        #expect(compact.first?.directors == ["Pete Docter"])
        #expect(compact.first?.cast.isEmpty == true)
        #expect(compact.first?.studio == "Pixar")
    }

    @Test func filterTypesDropNullDistinctValues() throws {
        let json = """
        {"director":[{"fieldValue":"Nolan","totalCount":5}],"exclusive":["Netflix",null],"genre":[{"fieldValue":"Drama","totalCount":9}],
         "holiday":[],"runtime":[{"min":70,"max":200}],"provider":[],"studio":null,
         "universes":[{"_id":"Marvel","fieldValue":"Marvel","noSubUniverseCount":1,"subUniverses":[{"fieldValue":"MCU","totalCount":3}],"totalCount":4},
                      {"_id":null,"fieldValue":null,"subUniverses":[],"totalCount":2}],
         "year":[2001,null,1999]}
        """
        let types = try decode(FilterTypes.self, json)
        #expect(types.exclusive == ["Netflix"])
        #expect(types.studio.isEmpty)
        #expect(types.year == [2001, 1999])
        #expect(types.runtimeBounds == 70...200)
        #expect(FilterOptions.universes(types.universes).map(\.title) == ["Other"])
    }

    @Test func tmdbDetailMapsToAnUnratedMovie() throws {
        let json = """
        {"adult":false,"budget":5,"genres":[{"id":1,"name":"Drama"},{"id":2,"name":"War"}],"id":42,"overview":"x","poster_path":"/d.jpg",
         "release_date":"2019-07-04","revenue":1234567,"runtime":null,"title":"Detail",
         "credits":{"cast":[{"name":"A"},{"name":"B"}],"crew":[{"name":"Dir","job":"Director"},{"name":"Prod","job":"Producer"}]},
         "videos":{"results":[{"key":"k1","site":"YouTube","type":"Teaser"},{"key":"k2","site":"YouTube","type":"Trailer"}]},
         "watch/providers":{"results":{"US":{"link":"https://jw","flatrate":[{"logo_path":"/n.jpg","provider_id":8,"provider_name":"Netflix","display_priority":1}]}}},
         "release_dates":{"results":[{"iso_3166_1":"US","release_dates":[{"certification":""},{"certification":"PG-13"}]}]},
         "recommendations":{"results":[{"id":7},{"id":9}]}}
        """
        let movie = try #require(Movie(unrated: try decode(TMDBMovieDetail.self, json)))
        #expect(movie.genre == "Drama" && movie.genre2 == "War")
        #expect(movie.year == 2019)
        #expect(movie.directors == ["Dir"])
        #expect(movie.rated == "PG-13")
        #expect(movie.trailer == "https://www.youtube.com/embed/k2")
        #expect(movie.provider.flatrate.first?.providerID == 8)
        #expect(movie.recommendations == [7, 9])
        #expect(movie.boxOffice == "1,234,567")
        #expect(movie.score == Movie.unratedScore)
    }

    @Test func adultTitlesAreDropped() {
        #expect(Movie(unrated: .fixture(adult: true)) == nil)
    }

    @Test func scoreGradientCoversEveryScore() {
        #expect(ScoreGradient.hexColors.count == 101)
        #expect(ScoreGradient.hex(for: 0) == "#b91c1c")
        #expect(ScoreGradient.hex(for: 50) == "#facc15")
        #expect(ScoreGradient.hex(for: 100) == "#15803d")
        #expect(ScoreGradient.hex(for: 150) == "#15803d")
        #expect(ScoreGradient.hex(for: -1) == nil)
        #expect(ScoreGradient.components(ofHex: "#ff0000")?.red == 1)
    }
}
