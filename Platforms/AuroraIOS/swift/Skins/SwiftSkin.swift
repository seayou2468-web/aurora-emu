import Foundation
import UIKit

struct SkinButton: Codable, Hashable {
    let id: String
    let title: String?
    let key: Int? // EmulatorKey raw value (nil means UI-only)
    let style: String?
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
                                SkinButton(id: "dpad_left", title: nil, key: Int(EMULATOR_KEY_LEFT.rawValue), style: "dpad", x: 0.08, y: 0.70, width: 0.10, height: 0.08),
                                SkinButton(id: "dpad_right", title: nil, key: Int(EMULATOR_KEY_RIGHT.rawValue), style: "dpad", x: 0.24, y: 0.70, width: 0.10, height: 0.08),
                                SkinButton(id: "dpad_up", title: nil, key: Int(EMULATOR_KEY_UP.rawValue), style: "dpad", x: 0.16, y: 0.62, width: 0.10, height: 0.08),
                                SkinButton(id: "dpad_down", title: nil, key: Int(EMULATOR_KEY_DOWN.rawValue), style: "dpad", x: 0.16, y: 0.78, width: 0.10, height: 0.08),
                                SkinButton(id: "y", title: "Y", key: Int(EMULATOR_KEY_B.rawValue), style: "face", x: 0.70, y: 0.58, width: 0.10, height: 0.08),
                                SkinButton(id: "x", title: "X", key: Int(EMULATOR_KEY_A.rawValue), style: "face", x: 0.84, y: 0.58, width: 0.10, height: 0.08),
                                SkinButton(id: "b", title: "B", key: Int(EMULATOR_KEY_B.rawValue), style: "face", x: 0.70, y: 0.74, width: 0.10, height: 0.08),
                                SkinButton(id: "a", title: "A", key: Int(EMULATOR_KEY_A.rawValue), style: "face", x: 0.84, y: 0.74, width: 0.10, height: 0.08),
                                SkinButton(id: "minus", title: "-", key: Int(EMULATOR_KEY_SELECT.rawValue), style: "system", x: 0.40, y: 0.84, width: 0.08, height: 0.06),
                                SkinButton(id: "plus", title: "+", key: Int(EMULATOR_KEY_START.rawValue), style: "system", x: 0.52, y: 0.84, width: 0.08, height: 0.06),
                                SkinButton(id: "home", title: "HOME", key: nil, style: "system", x: 0.64, y: 0.84, width: 0.10, height: 0.06),
                                SkinButton(id: "l", title: "L", key: Int(EMULATOR_KEY_L.rawValue), style: "shoulder", x: 0.05, y: 0.52, width: 0.16, height: 0.06),
                                SkinButton(id: "zl", title: "ZL", key: Int(EMULATOR_KEY_L.rawValue), style: "shoulder", x: 0.05, y: 0.44, width: 0.16, height: 0.06),
                                SkinButton(id: "r", title: "R", key: Int(EMULATOR_KEY_R.rawValue), style: "shoulder", x: 0.79, y: 0.52, width: 0.16, height: 0.06),
                                SkinButton(id: "zr", title: "ZR", key: Int(EMULATOR_KEY_R.rawValue), style: "shoulder", x: 0.79, y: 0.44, width: 0.16, height: 0.06)
                             ]),
        landscape: SkinLayout(backgroundImage: "default_landscape.png",
                              screen: SkinScreen(x: 0.18, y: 0.08, width: 0.46, height: 0.84),
                              buttons: [
                                SkinButton(id: "dpad_left", title: nil, key: Int(EMULATOR_KEY_LEFT.rawValue), style: "dpad", x: 0.04, y: 0.58, width: 0.08, height: 0.12),
                                SkinButton(id: "dpad_right", title: nil, key: Int(EMULATOR_KEY_RIGHT.rawValue), style: "dpad", x: 0.16, y: 0.58, width: 0.08, height: 0.12),
                                SkinButton(id: "dpad_up", title: nil, key: Int(EMULATOR_KEY_UP.rawValue), style: "dpad", x: 0.10, y: 0.44, width: 0.08, height: 0.12),
                                SkinButton(id: "dpad_down", title: nil, key: Int(EMULATOR_KEY_DOWN.rawValue), style: "dpad", x: 0.10, y: 0.72, width: 0.08, height: 0.12),
                                SkinButton(id: "y", title: "Y", key: Int(EMULATOR_KEY_B.rawValue), style: "face", x: 0.76, y: 0.34, width: 0.09, height: 0.12),
                                SkinButton(id: "x", title: "X", key: Int(EMULATOR_KEY_A.rawValue), style: "face", x: 0.86, y: 0.44, width: 0.09, height: 0.12),
                                SkinButton(id: "b", title: "B", key: Int(EMULATOR_KEY_B.rawValue), style: "face", x: 0.66, y: 0.44, width: 0.09, height: 0.12),
                                SkinButton(id: "a", title: "A", key: Int(EMULATOR_KEY_A.rawValue), style: "face", x: 0.76, y: 0.54, width: 0.09, height: 0.12),
                                SkinButton(id: "minus", title: "-", key: Int(EMULATOR_KEY_SELECT.rawValue), style: "system", x: 0.56, y: 0.82, width: 0.08, height: 0.08),
                                SkinButton(id: "plus", title: "+", key: Int(EMULATOR_KEY_START.rawValue), style: "system", x: 0.66, y: 0.82, width: 0.08, height: 0.08),
                                SkinButton(id: "home", title: "HOME", key: nil, style: "system", x: 0.76, y: 0.82, width: 0.10, height: 0.08),
                                SkinButton(id: "l", title: "L", key: Int(EMULATOR_KEY_L.rawValue), style: "shoulder", x: 0.20, y: 0.02, width: 0.12, height: 0.06),
                                SkinButton(id: "zl", title: "ZL", key: Int(EMULATOR_KEY_L.rawValue), style: "shoulder", x: 0.08, y: 0.02, width: 0.12, height: 0.06),
                                SkinButton(id: "r", title: "R", key: Int(EMULATOR_KEY_R.rawValue), style: "shoulder", x: 0.68, y: 0.02, width: 0.12, height: 0.06),
                                SkinButton(id: "zr", title: "ZR", key: Int(EMULATOR_KEY_R.rawValue), style: "shoulder", x: 0.80, y: 0.02, width: 0.12, height: 0.06)
                              ])
    )
}
