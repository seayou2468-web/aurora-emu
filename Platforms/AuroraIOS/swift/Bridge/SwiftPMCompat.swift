#if SWIFT_PACKAGE
import UIKit
import Foundation

typealias EmulatorCoreType = UInt32
typealias EmulatorKey = UInt32

let EMULATOR_CORE_TYPE_3DS: EmulatorCoreType = 0
let EMULATOR_CORE_TYPE_NDS: EmulatorCoreType = 1
let EMULATOR_CORE_TYPE_GBA: EmulatorCoreType = 2
let EMULATOR_CORE_TYPE_GB: EmulatorCoreType = 3
let EMULATOR_CORE_TYPE_NES: EmulatorCoreType = 4

@objcMembers
final class AURCoreSession: NSObject {
    func loadROM(at: URL) -> Bool { true }
    func loadBIOS(atPath: String) -> Bool { true }
    func setKey(_ key: EmulatorKey, pressed: Bool) {}
    func stepFrame() {}
    func lastError() -> String? { nil }
}

@objcMembers
final class AURCoreSessionFactory: NSObject {
    static func session(with coreType: EmulatorCoreType) -> AURCoreSession { AURCoreSession() }
}

final class AUREmulatorViewController: UIViewController {
    init(romURL: URL, coreType: EmulatorCoreType) {
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .black
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
