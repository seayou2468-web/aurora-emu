import Foundation
import UIKit

struct SkinButton: Codable, Hashable {
    let id: String
    let key: Int // EmulatorKey raw value
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

struct SkinScreen: Codable, Hashable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

struct SkinLayout: Codable, Hashable {
    let backgroundImage: String
    let screen: SkinScreen
    let buttons: [SkinButton]
}

struct SwiftSkin: Codable, Hashable {
    let id: String
    let name: String
    let portrait: SkinLayout
    let landscape: SkinLayout

    static let `default` = SwiftSkin(
        id: "default",
        name: "Default",
        portrait: SkinLayout(backgroundImage: "default_portrait.png",
                             screen: SkinScreen(x: 0, y: 0, width: 1.0, height: 0.5),
                             buttons: []),
        landscape: SkinLayout(backgroundImage: "default_landscape.png",
                              screen: SkinScreen(x: 0, y: 0, width: 0.5, height: 1.0),
                              buttons: [])
    )
}
