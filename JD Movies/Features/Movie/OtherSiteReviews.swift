import SwiftUI

/// IMDb, Rotten Tomatoes and Metacritic scores, when the catalogue has them.
struct OtherSiteReviews: View {
    let movie: Movie

    private struct Site: Identifiable {
        let name: String
        let image: ImageResource
        let urlString: String
        let value: String

        var id: String { name }
    }

    private var sites: [Site] {
        [
            Site(name: "IMDb", image: .imdb, urlString: "https://www.imdb.com/", value: movie.imdb),
            Site(name: "Rotten Tomatoes", image: .rottentomatoes, urlString: "https://www.rottentomatoes.com/", value: movie.rottenTomatoes),
            Site(name: "Metacritic", image: .metacritic, urlString: "https://www.metacritic.com/", value: movie.metacritic),
        ]
        .filter { !$0.value.isEmpty }
    }

    var body: some View {
        let sites = self.sites
        if !sites.isEmpty {
            VStack(spacing: 12) {
                ForEach(sites) { site in
                    HStack {
                        if let url = URL(string: site.urlString) {
                            Link(destination: url) {
                                logo(site)
                            }
                        } else {
                            logo(site)
                        }
                        Spacer()
                        Text(site.value)
                            .font(.headline)
                            .foregroundStyle(.appLight)
                    }
                }
            }
            .card()
        }
    }

    private func logo(_ site: Site) -> some View {
        Image(site.image)
            .resizable()
            .scaledToFit()
            .frame(height: 28)
            .accessibilityLabel(site.name)
    }
}
