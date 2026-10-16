import SwiftUI

// The website's palette (src/styles/tokens.ts): dark stone background, yellow accent.
nonisolated extension Color {
    static let appBackground = Color(hex: "#292524")
    static let appCard = Color(hex: "#44403c")
    static let appAccent = Color(hex: "#eab308")
    static let appMuted = Color(hex: "#78716c")
    static let appLight = Color(hex: "#f5f5f5")

    init(hex: String) {
        let components = ScoreGradient.components(ofHex: hex) ?? (red: 1, green: 0, blue: 1)
        self.init(red: components.red, green: components.green, blue: components.blue)
    }

    /// The red-to-green colour for a 0-100 score; the accent for unrated scores.
    static func score(_ score: Int) -> Color {
        ScoreGradient.hex(for: score).map { Color(hex: $0) } ?? .appAccent
    }

    static func score(_ average: Double) -> Color {
        ScoreGradient.hex(for: average).map { Color(hex: $0) } ?? .appAccent
    }
}

nonisolated extension ShapeStyle where Self == Color {
    static var appBackground: Color { .appBackground }
    static var appCard: Color { .appCard }
    static var appAccent: Color { .appAccent }
    static var appMuted: Color { .appMuted }
    static var appLight: Color { .appLight }
}

/// The site's `Item` paper: padded content on a card-coloured rounded rectangle.
struct CardModifier: ViewModifier {
    var alignment: Alignment = .leading

    func body(content: Content) -> some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, alignment: alignment)
            .background(Color.appCard, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Faint festive artwork behind Christmas movies, as on the website.
struct HolidayBackground: ViewModifier {
    let holiday: String?

    func body(content: Content) -> some View {
        content.background(alignment: .top) {
            if holiday == "Christmas" {
                Image(.christmas)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.18)
                    .allowsHitTesting(false)
            }
        }
    }
}

extension View {
    func card(alignment: Alignment = .leading) -> some View {
        modifier(CardModifier(alignment: alignment))
    }

    func holidayBackground(_ holiday: String?) -> some View {
        modifier(HolidayBackground(holiday: holiday))
    }

    /// The standard full-screen background for every tab and pushed screen.
    func screenBackground() -> some View {
        background(Color.appBackground.ignoresSafeArea())
    }
}

/// Section title used throughout, matching the site's bold row headers.
struct SectionTitle: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.title3.bold())
            .foregroundStyle(.appAccent)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
