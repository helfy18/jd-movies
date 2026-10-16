import SwiftUI

/// A titled, horizontally scrolling row of posters with an optional "View All" link.
struct PosterRow: View {
    let title: String
    let movies: [PosterMovie]
    var viewAll: MovieListQuery?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle(title)
                if let viewAll {
                    NavigationLink(value: Route.grid(viewAll)) {
                        HStack(spacing: 4) {
                            Text("VIEW ALL")
                            Image(systemName: "arrow.right")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.appAccent)
                    }
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(movies) { movie in
                        PosterLink(movie: movie)
                    }
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
    }
}
