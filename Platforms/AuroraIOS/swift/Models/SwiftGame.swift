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

// Ensure EmulatorCoreType is Sendable (it's a C enum, usually it is, but for Swift 6 transparency:)
extension EmulatorCoreType: @retroactive Sendable {}
extension EmulatorKey: @retroactive Sendable {}
extension EmulatorVideoSpec: @retroactive Sendable {}
