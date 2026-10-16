import Foundation

/// A filter value with the number of movies that carry it.
nonisolated struct FilterCount: Codable, Hashable, Sendable, Identifiable {
    var fieldValue: String
    var totalCount: Int

    var id: String { fieldValue }

    init(fieldValue: String, totalCount: Int) {
        self.fieldValue = fieldValue
        self.totalCount = totalCount
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fieldValue = try container.decodeIfPresent(String.self, forKey: .fieldValue) ?? ""
        totalCount = try container.decodeIfPresent(Int.self, forKey: .totalCount) ?? 0
    }
}

nonisolated struct UniverseType: Codable, Hashable, Sendable, Identifiable {
    var fieldValue: String
    var noSubUniverseCount: Int
    var subUniverses: [FilterCount]
    var totalCount: Int

    var id: String { fieldValue }
    /// Universes with several sub-universes get their own section in the picker.
    var isGrouped: Bool { subUniverses.count > 1 }

    init(fieldValue: String, noSubUniverseCount: Int = 0, subUniverses: [FilterCount] = [], totalCount: Int) {
        self.fieldValue = fieldValue
        self.noSubUniverseCount = noSubUniverseCount
        self.subUniverses = subUniverses
        self.totalCount = totalCount
    }

    enum CodingKeys: String, CodingKey {
        case fieldValue, noSubUniverseCount, subUniverses, totalCount
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fieldValue = try container.decodeIfPresent(String.self, forKey: .fieldValue) ?? ""
        noSubUniverseCount = try container.decodeIfPresent(Int.self, forKey: .noSubUniverseCount) ?? 0
        subUniverses = try container.decodeIfPresent([FilterCount].self, forKey: .subUniverses) ?? []
        totalCount = try container.decodeIfPresent(Int.self, forKey: .totalCount) ?? 0
    }
}

nonisolated struct RuntimeRange: Codable, Hashable, Sendable {
    var min: Int
    var max: Int
}

/// Every value the filter pickers can offer, from `/types/list`.
nonisolated struct FilterTypes: Codable, Hashable, Sendable {
    var director: [FilterCount]
    var exclusive: [String]
    var genre: [FilterCount]
    var holiday: [String]
    var runtime: [RuntimeRange]
    var provider: [ProviderInfo]
    var studio: [String]
    var universes: [UniverseType]
    var year: [Int]

    static let defaultRuntimeBounds = 0...300

    /// The catalogue's shortest and longest runtime, used as slider bounds.
    var runtimeBounds: ClosedRange<Int> {
        guard let range = runtime.first, range.min < range.max else {
            return FilterTypes.defaultRuntimeBounds
        }
        return range.min...range.max
    }

    init(director: [FilterCount] = [], exclusive: [String] = [], genre: [FilterCount] = [],
         holiday: [String] = [], runtime: [RuntimeRange] = [], provider: [ProviderInfo] = [],
         studio: [String] = [], universes: [UniverseType] = [], year: [Int] = []) {
        self.director = director
        self.exclusive = exclusive
        self.genre = genre
        self.holiday = holiday
        self.runtime = runtime
        self.provider = provider
        self.studio = studio
        self.universes = universes
        self.year = year
    }

    enum CodingKeys: String, CodingKey {
        case director, exclusive, genre, holiday, runtime, provider, studio, universes, year
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        director = try container.decodeIfPresent([FilterCount].self, forKey: .director) ?? []
        exclusive = try FilterTypes.strings(container, .exclusive)
        genre = try container.decodeIfPresent([FilterCount].self, forKey: .genre) ?? []
        holiday = try FilterTypes.strings(container, .holiday)
        runtime = try container.decodeIfPresent([RuntimeRange].self, forKey: .runtime) ?? []
        provider = try container.decodeIfPresent([ProviderInfo].self, forKey: .provider) ?? []
        studio = try FilterTypes.strings(container, .studio)
        universes = try container.decodeIfPresent([UniverseType].self, forKey: .universes) ?? []
        year = try (container.decodeIfPresent([Int?].self, forKey: .year) ?? []).compactMap { $0 }
    }

    /// Distinct-value lists can contain `null` for movies missing the field; drop those.
    private static func strings(_ container: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) throws -> [String] {
        let values = try container.decodeIfPresent([String?].self, forKey: key) ?? []
        return values.compactMap { $0?.nonEmpty }
    }
}
