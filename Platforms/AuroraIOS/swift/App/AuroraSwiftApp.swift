import UIKit

@main
final class AuroraSwiftApp: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Window creation is handled by AURSceneDelegate (UIWindowScene-based lifecycle).
        return true
    }
}
