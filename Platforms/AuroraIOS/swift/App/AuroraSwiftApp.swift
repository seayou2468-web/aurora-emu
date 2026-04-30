import UIKit

@main
final class AuroraSwiftApp: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
#if SWIFT_PACKAGE
        window.rootViewController = UINavigationController(rootViewController: AuroraCompatRootViewController())
#else
        window.rootViewController = UINavigationController(rootViewController: SwiftLibraryViewController())
#endif
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
