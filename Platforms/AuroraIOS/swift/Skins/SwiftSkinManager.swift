import Foundation
import UIKit

@MainActor final class SwiftSkinManager: ObservableObject {
    static let shared = SwiftSkinManager()
    @Published var availableSkins: [SwiftSkin] = []

    private let skinsFolder: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        skinsFolder = docs.appendingPathComponent("Skins")
        try? FileManager.default.createDirectory(at: skinsFolder, withIntermediateDirectories: true)
        ensureTemplateSkinExists()
        loadSkins()
    }

    func loadSkins() {
        guard let folders = try? FileManager.default.contentsOfDirectory(at: skinsFolder, includingPropertiesForKeys: nil) else { return }
        availableSkins = folders.compactMap { folder in
            let jsonURL = folder.appendingPathComponent("config.json")
            guard let data = try? Data(contentsOf: jsonURL) else { return nil }
            return try? JSONDecoder().decode(SwiftSkin.self, from: data)
        }
    }

    func ensureTemplateSkinExists() {
        let templateFolder = skinsFolder.appendingPathComponent("TemplateSkin")
        guard !FileManager.default.fileExists(atPath: templateFolder.path) else { return }
        try? FileManager.default.createDirectory(at: templateFolder, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(SwiftSkin.default) {
            try? data.write(to: templateFolder.appendingPathComponent("config.json"))
        }
    }

    func importSkin(at zipURL: URL) {
        // In a real iOS 26 app, we would use proper decompression.
        // Here we simulate the extraction to the skinsFolder.
        let skinID = zipURL.deletingPathExtension().lastPathComponent
        let targetFolder = skinsFolder.appendingPathComponent(skinID)
        try? FileManager.default.createDirectory(at: targetFolder, withIntermediateDirectories: true)

        // Simulating file moves for this task
        // try? FileManager.default.moveItem(at: zipURL, to: targetFolder.appendingPathComponent("archive.zip"))

        loadSkins()
    }

    func getSkinImage(skinID: String, imageName: String) -> UIImage? {
        let path = skinsFolder.appendingPathComponent(skinID).appendingPathComponent(imageName)
        return UIImage(contentsOfFile: path.path)
    }
}
