import SwiftUI

/// A poster tile: artwork, score and title on a card, like the site's `Poster`.
///
/// Horizontal rows use the fixed `rowWidth`; the grid passes `width: nil` so the
/// tile fills its column and three fit across an iPhone.
struct PosterView: View {
    static let rowWidth: CGFloat = 100

    let movie: PosterMovie
    var width: CGFloat? = PosterView.rowWidth

    var body: some View {
        VStack(spacing: 6) {
            Color.clear
                .aspectRatio(2 / 3, contentMode: .fit)
                .overlay {
                    RemoteImage(url: movie.posterURL(), contentMode: .fill) {
                        PosterPlaceholder()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    if movie.daniApproved {
                        DaniBadge(size: 36)
                    }
                }

            Text(movie.scoreLabel)
                .font(.footnote.weight(.bold))
                .foregroundStyle(Color.score(movie.score))

            Text(movie.title)
                .font(.caption)
                .foregroundStyle(.appLight)
                .multilineTextAlignment(.center)
                .lineLimit(3, reservesSpace: true)
        }
        .frame(width: width)
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(movie.title), \(movie.scoreLabel)")
    }
}

/// A poster that pushes the movie's detail screen.
struct PosterLink: View {
    let movie: PosterMovie
    var width: CGFloat? = PosterView.rowWidth

    var body: some View {
        NavigationLink(value: Route.movie(movie.tmdbID)) {
            PosterView(movie: movie, width: width)
        }
        .buttonStyle(.plain)
    }
}
