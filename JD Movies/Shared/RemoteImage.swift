import SwiftUI

/// An image fetched through the shared `ImageLoader`, with a placeholder until it arrives.
struct RemoteImage<Placeholder: View>: View {
    let url: URL?
    var contentMode: ContentMode = .fit
    @ViewBuilder let placeholder: () -> Placeholder

    @Environment(\.imageLoader) private var loader
    @State private var image: UIImage?

    init(url: URL?, contentMode: ContentMode = .fit, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            guard let url else {
                image = nil
                return
            }
            image = try? await loader.image(for: url)
        }
    }
}

/// Neutral stand-in while a poster loads or when a movie has none.
struct PosterPlaceholder: View {
    var body: some View {
        Rectangle()
            .fill(Color.appMuted.opacity(0.25))
            .overlay {
                Image(systemName: "film")
                    .font(.title)
                    .foregroundStyle(.appMuted)
            }
    }
}
