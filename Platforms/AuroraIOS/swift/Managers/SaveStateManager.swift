import Foundation
import UIKit

struct SaveStateMetadata: Codable {
    let slot: Int
    let date: Date
    let gameTitle: String
}

final class SaveStateManager {
    static let shared = SaveStateManager()
    private let fileManager = FileManager.default

    private func baseFolder(for gameTitle: String) -> URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = docs.appendingPathComponent("SaveStates").appendingPathComponent(gameTitle)
        try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    func save(data: Data, screenshot: UIImage?, slot: Int, gameTitle: String) {
        let folder = baseFolder(for: gameTitle)
        let dataURL = folder.appendingPathComponent("slot_\(slot).state")
        let imageURL = folder.appendingPathComponent("slot_\(slot).png")
        let metaURL = folder.appendingPathComponent("slot_\(slot).json")

        try? data.write(to: dataURL)
        if let screenshotData = screenshot?.pngData() {
            try? screenshotData.write(to: imageURL)
        }

        let meta = SaveStateMetadata(slot: slot, date: Date(), gameTitle: gameTitle)
        if let metaData = try? JSONEncoder().encode(meta) {
            try? metaData.write(to: metaURL)
        }
    }

    func load(slot: Int, gameTitle: String) -> Data? {
        let folder = baseFolder(for: gameTitle)
        let dataURL = folder.appendingPathComponent("slot_\(slot).state")
        return try? Data(contentsOf: dataURL)
    }

    func getMetadata(slot: Int, gameTitle: String) -> SaveStateMetadata? {
        let folder = baseFolder(for: gameTitle)
        let metaURL = folder.appendingPathComponent("slot_\(slot).json")
        guard let data = try? Data(contentsOf: metaURL) else { return nil }
        return try? JSONDecoder().decode(SaveStateMetadata.self, from: data)
    }

    func getScreenshot(slot: Int, gameTitle: String) -> UIImage? {
        let folder = baseFolder(for: gameTitle)
        let imageURL = folder.appendingPathComponent("slot_\(slot).png")
        guard let data = try? Data(contentsOf: imageURL) else { return nil }
        return UIImage(data: data)
    }
}
