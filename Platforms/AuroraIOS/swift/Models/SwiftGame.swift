import Foundation
import UIKit

enum SwiftLaunchTarget: String, Codable {
    case coreSession
}

struct SwiftROMItem: Identifiable, Codable {
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

import SwiftUI
extension SwiftROMItem {
    // Add SwiftUI Color conversion helper if needed, but I'll use native SwiftUI Color in the model for simplicity in this modernized version
}
