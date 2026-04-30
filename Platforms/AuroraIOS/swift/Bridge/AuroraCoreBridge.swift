import Foundation

final class AuroraCoreBridge {
    private var handle: OpaquePointer?

    init?(coreType: EmulatorCoreType) {
        guard let h = EmulatorCore_Create(coreType) else { return nil }
        self.handle = OpaquePointer(h)
    }

    deinit {
        if let handle { EmulatorCore_Destroy(UnsafeMutablePointer<EmulatorCoreHandle>(handle)) }
    }

    func loadROM(url: URL) -> Bool {
        guard let handle else { return false }
        return url.path.withCString { path in
            EmulatorCore_LoadROMFromPath(UnsafeMutablePointer<EmulatorCoreHandle>(handle), path)
        }
    }

    func stepFrame() {
        guard let handle else { return }
        EmulatorCore_StepFrame(UnsafeMutablePointer<EmulatorCoreHandle>(handle))
    }
}
