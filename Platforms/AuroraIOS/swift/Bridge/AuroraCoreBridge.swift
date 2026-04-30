import Foundation
import UIKit

final class AuroraCoreBridge {
    private var handle: OpaquePointer?

    init?(coreType: EmulatorCoreType) {
        // If EmulatorCore_Create returns a pointer that Swift sees as OpaquePointer,
        // we can assign it directly.
        guard let h = EmulatorCore_Create(coreType) else { return nil }
        self.handle = h
    }

    deinit {
        if let h = handle {
            EmulatorCore_Destroy(h)
        }
    }

    func loadROM(url: URL) -> Bool {
        guard let h = handle else { return false }
        return url.path.withCString { path in
            EmulatorCore_LoadROMFromPath(h, path)
        }
    }

    func setKey(_ key: EmulatorKey, pressed: Bool) {
        guard let h = handle else { return }
        EmulatorCore_SetKeyStatus(h, key, pressed)
    }

    func stepFrame() {
        guard let h = handle else { return }
        EmulatorCore_StepFrame(h)
    }

    func saveState() -> Data? {
        guard let h = handle else { return nil }
        var size: Int = 0
        _ = EmulatorCore_SaveStateToBuffer(h, nil, 0, &size)
        guard size > 0 else { return nil }

        var data = Data(count: size)
        data.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) in
            _ = EmulatorCore_SaveStateToBuffer(h, ptr.baseAddress, size, &size)
        }
        return data
    }

    func loadState(data: Data) -> Bool {
        guard let h = handle else { return false }
        return data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            EmulatorCore_LoadStateFromBuffer(h, ptr.baseAddress, data.count)
        }
    }

    func getVideoSpec() -> EmulatorVideoSpec? {
        guard let h = handle else { return nil }
        var spec = EmulatorVideoSpec()
        if EmulatorCore_GetVideoSpec(h, &spec) {
            return spec
        }
        return nil
    }

    func getFrameBuffer() -> UnsafePointer<UInt32>? {
        guard let h = handle else { return nil }
        var pixelCount: Int = 0
        return EmulatorCore_GetFrameBufferRGBA(h, &pixelCount)
    }
}
