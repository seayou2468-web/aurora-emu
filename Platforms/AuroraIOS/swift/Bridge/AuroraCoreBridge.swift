import Foundation

@objc enum AuroraCoreType: Int {
    case gba = 0
    case nes = 1
    case gb = 2
    case nds = 3
}

@objc enum AuroraCoreKey: Int {
    case a = 0
    case b = 1
    case select = 2
    case start = 3
    case right = 4
    case left = 5
    case up = 6
    case down = 7
    case r = 8
    case l = 9
}

@objcMembers
final class AuroraCoreBridge: NSObject {
    private let session: AURCoreSession

    init(coreType: AuroraCoreType) {
        let nativeType = EmulatorCoreType(rawValue: coreType.rawValue)!
        self.session = AURCoreSessionFactory.session(withCoreType: nativeType)
        super.init()
    }

    func loadROM(url: URL) -> Bool {
        session.loadROM(at: url)
    }

    func loadBIOS(path: String) -> Bool {
        session.loadBIOS(atPath: path)
    }

    func setKey(_ key: AuroraCoreKey, pressed: Bool) {
        guard let mapped = EmulatorKey(rawValue: key.rawValue) else { return }
        session.setKey(mapped, pressed: pressed)
    }

    func stepFrame() {
        session.stepFrame()
    }

    var lastError: String? {
        session.lastError()
    }
}
