import SwiftUI

/// A horizontally scrolling row of headshots with name and character, each pushing the person screen.
struct CastSection: View {
    let cast: [CastMember]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle("Cast")
                .padding(.horizontal)

            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(cast) { member in
                        NavigationLink(value: Route.person(member.name)) {
                            CastCard(member: member)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
    }
}

struct CastCard: View {
    static let width: CGFloat = 100

    let member: CastMember

    var body: some View {
        VStack(spacing: 6) {
            Group {
                if let url = member.photoURL {
                    RemoteImage(url: url, contentMode: .fill) {
                        PosterPlaceholder()
                    }
                } else {
                    Rectangle()
                        .fill(Color.appMuted.opacity(0.25))
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.appMuted)
                        }
                }
            }
            .frame(width: Self.width, height: Self.width * 1.5)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            Text(member.name)
                .font(.caption.weight(.bold))
                .foregroundStyle(.appLight)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)

            Text(member.character)
                .font(.caption2)
                .foregroundStyle(.appMuted)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
        }
        .frame(width: Self.width)
        .padding(8)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(member.character.isEmpty ? member.name : "\(member.name) as \(member.character)")
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ScrollView {
            CastSection(cast: [
                CastMember(name: "Al Pacino", character: "Lt. Vincent Hanna", tmdbID: 1158),
                CastMember(name: "Robert De Niro", character: "Neil McCauley", tmdbID: 380),
                CastMember(name: "Val Kilmer"),
            ])
        }
        .screenBackground()
        .appDestinations()
    }
    .environment(AppEnvironment.preview(ratings: StubRatingsService()))
    .preferredColorScheme(.dark)
}
#endif
