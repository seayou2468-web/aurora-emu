import Foundation
import UIKit

final class AuroraCoreBridge {
    private var handle: OpaquePointer?

    init?(coreType: EmulatorCoreType) {
        guard let h = EmulatorCore_Create(coreType) else { return nil }
        self.handle = OpaquePointer(h)
    }

    deinit {
        if let handle {
            EmulatorCore_Destroy(UnsafeMutablePointer<EmulatorCoreHandle>(handle))
        }
    }

    func loadROM(url: URL) -> Bool {
        guard let handle else { return false }
        return url.path.withCString { path in
            EmulatorCore_LoadROMFromPath(UnsafeMutablePointer<EmulatorCoreHandle>(handle), path)
        }
    }

    func setKey(_ key: EmulatorKey, pressed: Bool) {
        guard let handle else { return }
        EmulatorCore_SetKeyStatus(UnsafeMutablePointer<EmulatorCoreHandle>(handle), key, pressed)
    }

    func stepFrame() {
        guard let handle else { return }
        EmulatorCore_StepFrame(UnsafeMutablePointer<EmulatorCoreHandle>(handle))
    }

    func saveState() -> Data? {
        guard let handle else { return nil }
        var size: Int = 0
        let h = UnsafeMutablePointer<EmulatorCoreHandle>(handle)
        _ = EmulatorCore_SaveStateToBuffer(h, nil, 0, &size)
        guard size > 0 else { return nil }

        var data = Data(count: size)
        data.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) in
            _ = EmulatorCore_SaveStateToBuffer(h, ptr.baseAddress, size, &size)
        }
        return data
    }

    func loadState(data: Data) -> Bool {
        guard let handle else { return false }
        let h = UnsafeMutablePointer<EmulatorCoreHandle>(handle)
        return data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            EmulatorCore_LoadStateFromBuffer(h, ptr.baseAddress, data.count)
        }
    }

    func getVideoSpec() -> EmulatorVideoSpec? {
        guard let handle else { return nil }
        var spec = EmulatorVideoSpec()
        if EmulatorCore_GetVideoSpec(UnsafePointer<EmulatorCoreHandle>(handle), &spec) {
            return spec
        }
        return nil
    }

    func getFrameBuffer() -> UnsafePointer<UInt32>? {
        guard let handle else { return nil }
        var pixelCount: Int = 0
        return EmulatorCore_GetFrameBufferRGBA(UnsafeMutablePointer<EmulatorCoreHandle>(handle), &pixelCount)
    }
}
