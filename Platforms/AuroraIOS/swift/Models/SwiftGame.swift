import Foundation
import SwiftUI

enum SwiftLaunchTarget: String, Codable, Sendable {
    case coreSession
}

struct SwiftROMItem: Identifiable, Codable, Sendable {
    let id: UUID
    let url: URL
    let title: String
    let launchTarget: SwiftLaunchTarget
    let extensionLabel: String
    let coreType: EmulatorCoreType
    let addedDate: Date
    let fileSizeBytes: Int64

    var accentColor: Color {
        switch coreType {
        case EMULATOR_CORE_TYPE_NDS: return .indigo
        case EMULATOR_CORE_TYPE_GBA: return .purple
        case EMULATOR_CORE_TYPE_GB: return .green
        case EMULATOR_CORE_TYPE_NES: return .red
        default: return .gray
        }
    }

    init(id: UUID = UUID(), url: URL, title: String, launchTarget: SwiftLaunchTarget, extensionLabel: String, coreType: EmulatorCoreType, addedDate: Date, fileSizeBytes: Int64) {
        self.id = id
        self.url = url
        self.title = title
        self.launchTarget = launchTarget
        self.extensionLabel = extensionLabel
        self.coreType = coreType
        self.addedDate = addedDate
        self.fileSizeBytes = fileSizeBytes
    }
}

extension EmulatorCoreType: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(UInt32.self)
        self.init(rawValue: raw)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}

extension EmulatorCoreType: @unchecked Sendable {}
extension EmulatorKey: @unchecked Sendable {}
extension EmulatorVideoSpec: @unchecked Sendable {}
extension EmulatorPixelFormat: @unchecked Sendable {}
