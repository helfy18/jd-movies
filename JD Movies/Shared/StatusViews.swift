import SwiftUI

struct LoadingView: View {
    var body: some View {
        ProgressView()
            .controlSize(.large)
            .tint(.appAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 80)
    }
}

struct ErrorView: View {
    let message: String
    var retry: (() async -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.appMuted)
            Text(message)
                .foregroundStyle(.appLight)
                .multilineTextAlignment(.center)
            if let retry {
                Button("Try again") {
                    Task { await retry() }
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal)
    }
}

struct MessageView: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .foregroundStyle(.appMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
    }
}
