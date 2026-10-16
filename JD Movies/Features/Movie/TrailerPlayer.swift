import SwiftUI
import WebKit

/// Plays a YouTube embed inline, matching the website's trailer iframe.
///
/// YouTube's player refuses to play without an HTTP Referer, so the embed is
/// loaded as a top-level request that names the website as the referring page.
struct TrailerPlayer: UIViewRepresentable {
    let url: URL
    /// The page YouTube should see as the embedding site.
    let referrer: URL

    final class Coordinator {
        var loadedURL: URL?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.loadedURL != url else { return }
        context.coordinator.loadedURL = url
        webView.load(request)
    }

    private var request: URLRequest {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var items = components?.queryItems ?? []
        items += [
            URLQueryItem(name: "playsinline", value: "1"),
            URLQueryItem(name: "rel", value: "0"),
            URLQueryItem(name: "origin", value: referrer.absoluteString),
        ]
        components?.queryItems = items
        var request = URLRequest(url: components?.url ?? url)
        request.setValue(referrer.absoluteString, forHTTPHeaderField: "Referer")
        return request
    }
}
