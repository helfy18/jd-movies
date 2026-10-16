import Foundation

/// Red (0) through yellow (50) to green (100), one hex colour per score.
/// Generated from the website's src/styles/gradient.ts; keep the two in sync.
nonisolated enum ScoreGradient {
    static let hexColors: [String] = [
        "#b91c1c", "#ba201c", "#bc231c", "#bd271c", "#be2a1b", "#c02e1b", "#c1311b", "#c2351b",
        "#c3381b", "#c53c1b", "#c63f1b", "#c7431a", "#c9461a", "#ca4a1a", "#cb4d1a", "#cd511a",
        "#ce541a", "#cf581a", "#d05b19", "#d25f19", "#d36219", "#d46619", "#d66919", "#d76d19",
        "#d87019", "#da7419", "#db7818", "#dc7b18", "#dd7f18", "#df8218", "#e08618", "#e18918",
        "#e38d18", "#e49017", "#e59417", "#e79717", "#e89b17", "#e99e17", "#eaa217", "#eca517",
        "#eda916", "#eeac16", "#f0b016", "#f1b316", "#f2b716", "#f4ba16", "#f5be16", "#f6c115",
        "#f7c515", "#f9c815", "#facc15", "#f5ca16", "#f1c917", "#ecc717", "#e8c618", "#e3c419",
        "#dfc31a", "#dac11b", "#d5c01b", "#d1be1c", "#ccbd1d", "#c8bb1e", "#c3ba1f", "#beb81f",
        "#bab720", "#b5b521", "#b1b422", "#acb223", "#a8b123", "#a3af24", "#9eae25", "#9aac26",
        "#95ab27", "#91a927", "#8ca828", "#88a629", "#83a42a", "#7ea32b", "#7aa12b", "#75a02c",
        "#719e2d", "#6c9d2e", "#679b2f", "#639a2f", "#5e9830", "#5a9731", "#559532", "#519433",
        "#4c9233", "#479134", "#438f35", "#3e8e36", "#3a8c37", "#358b37", "#308938", "#2c8839",
        "#27863a", "#23853b", "#1e833b", "#1a823c", "#15803d",
    ]

    /// The colour for a score, or `nil` for unrated (negative) scores.
    static func hex(for score: Int) -> String? {
        guard score >= 0 else { return nil }
        return hexColors[min(hexColors.count - 1, score)]
    }

    static func hex(for score: Double) -> String? {
        guard score >= 0 else { return nil }
        return hex(for: Int(score.rounded()))
    }

    /// Red, green and blue components in 0...1 for a hex colour like "#b91c1c".
    static func components(ofHex hex: String) -> (red: Double, green: Double, blue: Double)? {
        let digits = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return nil }
        return (Double((value >> 16) & 0xFF) / 255,
                Double((value >> 8) & 0xFF) / 255,
                Double(value & 0xFF) / 255)
    }
}
