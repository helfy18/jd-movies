import Foundation

/// One selectable value in a filter picker.
nonisolated struct PickerOption: Hashable, Sendable, Identifiable {
    let value: String
    let label: String
    let imageURL: URL?

    var id: String { value }

    init(_ value: String, label: String? = nil, imageURL: URL? = nil) {
        self.value = value
        self.label = label ?? value
        self.imageURL = imageURL
    }
}

nonisolated struct PickerSection: Hashable, Sendable, Identifiable {
    let title: String?
    let options: [PickerOption]

    var id: String { title ?? "" }

    init(title: String? = nil, options: [PickerOption]) {
        self.title = title
        self.options = options
    }

    init(title: String? = nil, values: [String]) {
        self.init(title: title, options: values.map { PickerOption($0) })
    }
}

/// Turns `/types/list` data into the sections each filter picker shows.
nonisolated enum FilterOptions {
    static let popularGenreCount = 10

    private static func byName(_ lhs: String, _ rhs: String) -> Bool {
        lhs.localizedCompare(rhs) == .orderedAscending
    }

    /// The ten most common genres first, then the rest, each sorted by name.
    static func genres(_ genres: [FilterCount]) -> [PickerSection] {
        let ordered = genres
            .filter { !$0.fieldValue.isEmpty }
            .sorted { $0.totalCount != $1.totalCount ? $0.totalCount > $1.totalCount : byName($0.fieldValue, $1.fieldValue) }
            .map(\.fieldValue)
        let popular = ordered.prefix(popularGenreCount).sorted(by: byName)
        let more = ordered.dropFirst(popularGenreCount).sorted(by: byName)
        var sections = [PickerSection(title: "Popular Genres", values: popular)]
        if !more.isEmpty { sections.append(PickerSection(title: "More Genres", values: more)) }
        return sections
    }

    /// Grouped universes (several sub-universes) first by size, then the rest by name.
    static func sortedUniverses(_ universes: [UniverseType]) -> [UniverseType] {
        universes
            .filter { !$0.fieldValue.isEmpty }
            .sorted { lhs, rhs in
                if lhs.isGrouped != rhs.isGrouped { return lhs.isGrouped }
                if lhs.isGrouped { return lhs.totalCount > rhs.totalCount }
                return byName(lhs.fieldValue, rhs.fieldValue)
            }
    }

    /// A section per grouped universe (its sub-universes plus "All X"), then an "Other" section.
    static func universes(_ universes: [UniverseType]) -> [PickerSection] {
        let sorted = sortedUniverses(universes)
        var sections: [PickerSection] = sorted.filter(\.isGrouped).map { universe in
            let subs = universe.subUniverses
                .map(\.fieldValue)
                .filter { !$0.isEmpty }
                .sorted(by: byName)
                .map { PickerOption($0) }
            let all = PickerOption(universe.fieldValue, label: "All \(universe.fieldValue)")
            return PickerSection(title: universe.fieldValue, options: subs + [all])
        }
        let other = sorted.filter { !$0.isGrouped }.map(\.fieldValue)
        if !other.isEmpty { sections.append(PickerSection(title: "Other", values: other)) }
        return sections
    }

    static func directors(_ directors: [FilterCount]) -> [String] {
        directors.map(\.fieldValue).filter { !$0.isEmpty }.sorted(by: byName)
    }

    /// Newest first.
    static func years(_ years: [Int]) -> [String] {
        years.sorted(by: >).map(String.init)
    }

    /// "1990-1999" style labels for every decade present, newest first.
    static func decades(fromYears years: [Int]) -> [String] {
        let starts = Set(years.map { $0 / 10 * 10 })
        return starts.sorted(by: >).map { "\($0)-\($0 + 9)" }
    }

    static func providers(_ providers: [ProviderInfo]) -> [PickerOption] {
        providers.map { PickerOption(String($0.providerID), label: $0.providerName, imageURL: $0.logoURL) }
    }

    /// Display name for a selected provider id.
    static func providerName(for id: String, in providers: [ProviderInfo]) -> String {
        providers.first { String($0.providerID) == id }?.providerName ?? id
    }
}
