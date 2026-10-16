import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 10) {
                        Image(.popcorn)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 44)
                        Text("JD MOVIES")
                            .font(.system(.title, design: .monospaced, weight: .bold))
                            .foregroundStyle(.appAccent)
                    }
                    .frame(maxWidth: .infinity)

                    Text("Hello, my name is Johnathan, and I built this app to showcase my movie ratings. I will consistently be adding new ratings as I watch them.\n\nLook out for upgrades as well!")
                        .foregroundStyle(.appLight)

                    Link(destination: environment.configuration.siteBaseURL) {
                        Label(environment.configuration.siteBaseURL.host() ?? "Website", systemImage: "safari")
                    }

                    HStack(spacing: 24) {
                        if let tmdb = URL(string: "https://www.themoviedb.org/") {
                            Link(destination: tmdb) {
                                Image(.tmdb)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 32)
                                    .accessibilityLabel("TMDB")
                            }
                        }
                        if let letterboxd = URL(string: "https://letterboxd.com/helfy18/") {
                            Link(destination: letterboxd) {
                                Image(.letterboxd)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 32)
                                    .accessibilityLabel("Letterboxd")
                            }
                        }
                    }

                    Text("Posters, provider availability and theatre listings come from TMDB and JustWatch. This product uses the TMDB API but is not endorsed or certified by TMDB.")
                        .font(.footnote)
                        .foregroundStyle(.appMuted)
                }
                .padding()
            }
            .screenBackground()
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    AboutView()
        .environment(AppEnvironment.preview())
        .preferredColorScheme(.dark)
}
#endif
