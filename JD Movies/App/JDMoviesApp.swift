import SwiftUI

@main
struct JDMoviesApp: App {
    @State private var environment = AppEnvironment.live()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(environment)
                .environment(\.imageLoader, environment.imageLoader)
                .preferredColorScheme(.dark)
                .tint(.appAccent)
        }
    }
}
