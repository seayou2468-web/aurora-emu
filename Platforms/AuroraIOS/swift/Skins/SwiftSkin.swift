import UIKit

struct SwiftSkin: Codable, Hashable {
    var id: String
    var name: String
    var overlayImageName: String?
    var opacity: Double
    static let `default` = SwiftSkin(id: "default", name: "Default", overlayImageName: nil, opacity: 1.0)
}
