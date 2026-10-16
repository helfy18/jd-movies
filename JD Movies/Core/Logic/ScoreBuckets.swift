import Foundation

nonisolated struct ScoreBucket: Hashable, Sendable, Identifiable {
    let label: String
    let range: ClosedRange<Int>
    /// Score used to colour the bucket's bar.
    let midpoint: Int

    var id: String { label }
}

nonisolated struct BucketCount: Hashable, Sendable, Identifiable {
    let bucket: ScoreBucket
    let count: Int

    var id: String { bucket.id }
}

nonisolated enum ScoreBuckets {
    /// The coarse buckets shown on a person's page.
    static let person: [ScoreBucket] = [
        ScoreBucket(label: "<20", range: 0...19, midpoint: 10),
        ScoreBucket(label: "20-40", range: 20...39, midpoint: 30),
        ScoreBucket(label: "40-60", range: 40...59, midpoint: 50),
        ScoreBucket(label: "60s", range: 60...69, midpoint: 65),
        ScoreBucket(label: "70s", range: 70...79, midpoint: 75),
        ScoreBucket(label: "80s", range: 80...89, midpoint: 85),
        ScoreBucket(label: "90s", range: 90...100, midpoint: 95),
    ]

    static func counts(of scores: [Int], in buckets: [ScoreBucket] = person) -> [BucketCount] {
        buckets.map { bucket in
            BucketCount(bucket: bucket, count: scores.filter { bucket.range.contains($0) }.count)
        }
    }

    /// The stats page histogram: one bucket per `SiteStats.bucketSize` points, 100 in the last.
    static func histogram(_ distribution: [Int]) -> [BucketCount] {
        distribution.enumerated().map { index, count in
            let lower = index * SiteStats.bucketSize
            let upper = index == distribution.count - 1 ? 100 : lower + SiteStats.bucketSize - 1
            let bucket = ScoreBucket(label: "\(lower)-\(upper)", range: lower...upper, midpoint: lower + 2)
            return BucketCount(bucket: bucket, count: count)
        }
    }
}
