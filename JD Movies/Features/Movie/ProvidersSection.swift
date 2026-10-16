import SwiftUI

/// Where to watch, with each logo deep-linking to that provider's search.
struct ProvidersSection: View {
    let movie: Movie
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Providers")
                    .font(.headline)
                    .foregroundStyle(.appAccent)
                Text("Brought to you by JustWatch.com")
                    .font(.caption)
                    .foregroundStyle(.appMuted)
            }
            providerRow("With Account", movie.provider.flatrate)
            let free = movie.provider.freeToWatch
            if !free.isEmpty {
                providerRow("For Free", free)
            }
            providerRow("For Rent", movie.provider.rent)
            providerRow("To Buy", movie.provider.buy)
        }
        .card()
    }

    private func providerRow(_ label: String, _ providers: [ProviderInfo]) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .foregroundStyle(.appAccent)
                .frame(width: 96, alignment: .leading)
            if providers.isEmpty {
                Text("Not Available")
                    .foregroundStyle(.appMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(providers) { provider in
                        Button {
                            open(provider)
                        } label: {
                            RemoteImage(url: provider.logoURL, contentMode: .fill) {
                                Color.appMuted.opacity(0.3)
                            }
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(provider.providerName)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func open(_ provider: ProviderInfo) {
        let link = ProviderSearch.url(providerID: provider.providerID, title: movie.title, fallback: movie.provider.link)
        if let url = URL(string: link) {
            openURL(url)
        }
    }
}
