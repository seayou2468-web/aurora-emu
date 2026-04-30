import Foundation
import SwiftUI

struct SwiftROMItem: Identifiable, Codable, Sendable {
    let id: UUID
    let url: URL
    let title: String
    let launchTarget: String // For simplicity
    let extensionLabel: String
    let coreType: EmulatorCoreType
    let addedDate: Date
    let fileSizeBytes: Int64

    var accentColor: Color {
        switch coreType {
        case EMULATOR_CORE_TYPE_GBA: return .purple
        case EMULATOR_CORE_TYPE_NES: return .red
        case EMULATOR_CORE_TYPE_GB:  return .green
        case EMULATOR_CORE_TYPE_NDS: return .indigo
        default: return .gray
        }
    }
}

extension EmulatorCoreType: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let val = try container.decode(UInt32.self)
        self.init(rawValue: val)
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
