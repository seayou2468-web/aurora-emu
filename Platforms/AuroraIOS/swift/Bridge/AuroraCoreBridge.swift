import Foundation
import UIKit

// The C API returns OpaquePointer directly for Handle in some versions or EmulatorCoreHandle pointer.
// Based on the error, EmulatorCore_Create returns OpaquePointer.

final class AuroraCoreBridge {
    private var handle: OpaquePointer?

    init?(coreType: EmulatorCoreType) {
        guard let h = EmulatorCore_Create(coreType) else { return nil }
        self.handle = h
    }

    deinit {
        if let handle = handle {
            EmulatorCore_Destroy(handle)
        }
    }

    func loadROM(url: URL) -> Bool {
        guard let handle = handle else { return false }
        return url.path.withCString { path in
            EmulatorCore_LoadROMFromPath(handle, path)
        }
    }

    func setKey(_ key: EmulatorKey, pressed: Bool) {
        guard let handle = handle else { return }
        EmulatorCore_SetKeyStatus(handle, key, pressed)
    }

    func stepFrame() {
        guard let handle = handle else { return }
        EmulatorCore_StepFrame(handle)
    }

    func saveState() -> Data? {
        guard let handle = handle else { return nil }
        var size: Int = 0
        _ = EmulatorCore_SaveStateToBuffer(handle, nil, 0, &size)
        guard size > 0 else { return nil }

        var data = Data(count: size)
        data.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) in
            _ = EmulatorCore_SaveStateToBuffer(handle, ptr.baseAddress, size, &size)
        }
        return data
    }

    func loadState(data: Data) -> Bool {
        guard let handle = handle else { return false }
        return data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            EmulatorCore_LoadStateFromBuffer(handle, ptr.baseAddress, data.count)
        }
    }

    func getVideoSpec() -> EmulatorVideoSpec? {
        guard let handle = handle else { return nil }
        var spec = EmulatorVideoSpec()
        if EmulatorCore_GetVideoSpec(handle, &spec) {
            return spec
        }
        return nil
    }

    func getFrameBuffer() -> UnsafePointer<UInt32>? {
        guard let handle = handle else { return nil }
        var pixelCount: Int = 0
        return EmulatorCore_GetFrameBufferRGBA(handle, &pixelCount)
    }
}
