import SwiftUI
import UIKit

/// Downloads and caches poster, profile and logo images.
///
/// Decoded images live in an `NSCache`; raw responses go through a generous
/// `URLCache` so posters survive relaunches without re-downloading.
actor ImageLoader {
    private let session: URLSession
    private let memory = NSCache<NSURL, UIImage>()
    private var inflight: [URL: Task<UIImage, any Error>] = [:]

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(memoryCapacity: 32 << 20, diskCapacity: 256 << 20)
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: configuration)
        memory.totalCostLimit = 96 << 20
    }

    func image(for url: URL) async throws -> UIImage {
        if let cached = memory.object(forKey: url as NSURL) {
            return cached
        }
        if let running = inflight[url] {
            return try await running.value
        }
        let task = Task<UIImage, any Error> { [session] in
            let (data, _) = try await session.data(from: url)
            guard let image = UIImage(data: data) else { throw URLError(.cannotDecodeContentData) }
            let prepared = await image.byPreparingForDisplay()
            return prepared ?? image
        }
        inflight[url] = task
        defer { inflight[url] = nil }
        let image = try await task.value
        let pixels = image.size.width * image.size.height * image.scale * image.scale
        memory.setObject(image, forKey: url as NSURL, cost: Int(pixels) * 4)
        return image
    }
}

private nonisolated struct ImageLoaderKey: EnvironmentKey {
    static let defaultValue = ImageLoader()
}

extension EnvironmentValues {
    var imageLoader: ImageLoader {
        get { self[ImageLoaderKey.self] }
        set { self[ImageLoaderKey.self] = newValue }
    }
}
