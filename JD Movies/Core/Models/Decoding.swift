import Foundation

/// Lenient decoding helpers for the ratings API, which is written in Go and
/// serialises nil slices as `null` and unset fields as zero values.
nonisolated extension KeyedDecodingContainer {
    func decodeArray<Element: Decodable>(_ type: Element.Type = Element.self, forKey key: Key) throws -> [Element] {
        try decodeIfPresent([Element].self, forKey: key) ?? []
    }

    func decodeString(forKey key: Key) throws -> String {
        try decodeIfPresent(String.self, forKey: key) ?? ""
    }

    func decodeInt(forKey key: Key) throws -> Int {
        try decodeIfPresent(Int.self, forKey: key) ?? 0
    }

    func decodeBool(forKey key: Key) throws -> Bool {
        try decodeIfPresent(Bool.self, forKey: key) ?? false
    }
}

nonisolated extension String {
    /// `nil` when the string is empty. The API uses `""` for "not set".
    var nonEmpty: String? { isEmpty ? nil : self }
}
