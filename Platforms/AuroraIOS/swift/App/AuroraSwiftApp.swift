import SwiftUI

@main
struct AuroraSwiftApp: App {
    var body: some Scene {
        WindowGroup {
            SwiftLibraryView()
                .preferredColorScheme(.dark)
        }
    }
}
