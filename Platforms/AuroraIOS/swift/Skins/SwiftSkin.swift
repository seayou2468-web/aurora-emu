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
                             screen: SkinScreen(x: 0.08, y: 0.08, width: 0.84, height: 0.42),
                             buttons: [
                                SkinButton(id: "dpad_left", key: Int(EMULATOR_KEY_LEFT.rawValue), x: 0.08, y: 0.70, width: 0.10, height: 0.08),
                                SkinButton(id: "dpad_right", key: Int(EMULATOR_KEY_RIGHT.rawValue), x: 0.24, y: 0.70, width: 0.10, height: 0.08),
                                SkinButton(id: "dpad_up", key: Int(EMULATOR_KEY_UP.rawValue), x: 0.16, y: 0.62, width: 0.10, height: 0.08),
                                SkinButton(id: "dpad_down", key: Int(EMULATOR_KEY_DOWN.rawValue), x: 0.16, y: 0.78, width: 0.10, height: 0.08),
                                SkinButton(id: "a", key: Int(EMULATOR_KEY_A.rawValue), x: 0.78, y: 0.66, width: 0.12, height: 0.10),
                                SkinButton(id: "b", key: Int(EMULATOR_KEY_B.rawValue), x: 0.64, y: 0.72, width: 0.12, height: 0.10),
                                SkinButton(id: "start", key: Int(EMULATOR_KEY_START.rawValue), x: 0.50, y: 0.84, width: 0.10, height: 0.06),
                                SkinButton(id: "select", key: Int(EMULATOR_KEY_SELECT.rawValue), x: 0.38, y: 0.84, width: 0.10, height: 0.06),
                                SkinButton(id: "l", key: Int(EMULATOR_KEY_L.rawValue), x: 0.05, y: 0.52, width: 0.16, height: 0.06),
                                SkinButton(id: "r", key: Int(EMULATOR_KEY_R.rawValue), x: 0.79, y: 0.52, width: 0.16, height: 0.06)
                             ]),
        landscape: SkinLayout(backgroundImage: "default_landscape.png",
                              screen: SkinScreen(x: 0.18, y: 0.08, width: 0.46, height: 0.84),
                              buttons: [
                                SkinButton(id: "dpad_left", key: Int(EMULATOR_KEY_LEFT.rawValue), x: 0.04, y: 0.58, width: 0.08, height: 0.12),
                                SkinButton(id: "dpad_right", key: Int(EMULATOR_KEY_RIGHT.rawValue), x: 0.16, y: 0.58, width: 0.08, height: 0.12),
                                SkinButton(id: "dpad_up", key: Int(EMULATOR_KEY_UP.rawValue), x: 0.10, y: 0.44, width: 0.08, height: 0.12),
                                SkinButton(id: "dpad_down", key: Int(EMULATOR_KEY_DOWN.rawValue), x: 0.10, y: 0.72, width: 0.08, height: 0.12),
                                SkinButton(id: "a", key: Int(EMULATOR_KEY_A.rawValue), x: 0.84, y: 0.46, width: 0.10, height: 0.14),
                                SkinButton(id: "b", key: Int(EMULATOR_KEY_B.rawValue), x: 0.74, y: 0.62, width: 0.10, height: 0.14),
                                SkinButton(id: "start", key: Int(EMULATOR_KEY_START.rawValue), x: 0.66, y: 0.82, width: 0.09, height: 0.08),
                                SkinButton(id: "select", key: Int(EMULATOR_KEY_SELECT.rawValue), x: 0.56, y: 0.82, width: 0.09, height: 0.08),
                                SkinButton(id: "l", key: Int(EMULATOR_KEY_L.rawValue), x: 0.20, y: 0.02, width: 0.12, height: 0.06),
                                SkinButton(id: "r", key: Int(EMULATOR_KEY_R.rawValue), x: 0.68, y: 0.02, width: 0.12, height: 0.06)
                              ])
    )
}
