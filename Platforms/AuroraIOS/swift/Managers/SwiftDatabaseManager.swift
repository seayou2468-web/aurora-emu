import Foundation

enum SwiftBIOSKey: String, Codable, CaseIterable {
    case ndsArm9 = "nds_arm9"
    case ndsArm7 = "nds_arm7"
    case ndsFirmware = "nds_firmware"
    case gba
    case gb
    case gbc
}

final class SwiftDatabaseManager {
    static let shared = SwiftDatabaseManager()

    private struct Payload: Codable {
        var games: [SwiftGame]
        var biosPaths: [SwiftBIOSKey: String]
    }

    private let queue = DispatchQueue(label: "aurora.db.queue", qos: .userInitiated)
    private var payload: Payload

    private init() {
        self.payload = Payload(games: [], biosPaths: [:])
        self.payload = load()
    }

    func games(systemIdentifier: String? = nil) -> [SwiftGame] {
        queue.sync {
            guard let systemIdentifier else { return payload.games }
            return payload.games.filter { $0.systemIdentifier == systemIdentifier }
        }
    }

    func upsertGame(_ game: SwiftGame) {
        queue.sync {
            if let i = payload.games.firstIndex(where: { $0.romPath == game.romPath }) { payload.games[i] = game }
            else { payload.games.append(game) }
            save()
        }
    }

    func removeGame(id: UUID, removeROMFile: Bool) {
        queue.sync {
            guard let i = payload.games.firstIndex(where: { $0.id == id }) else { return }
            let target = payload.games.remove(at: i)
            if removeROMFile { try? FileManager.default.removeItem(atPath: target.romPath) }
            save()
        }
    }

    func setBIOSURL(_ url: URL, for key: SwiftBIOSKey) {
        queue.sync {
            guard let rel = persistBIOS(at: url, key: key) else { return }
            payload.biosPaths[key] = rel
            save()
        }
    }

    func biosFullPath(for key: SwiftBIOSKey) -> String? {
        queue.sync {
            guard let rel = payload.biosPaths[key] else { return nil }
            let full = documentsDirectory.appendingPathComponent(rel).path
            return FileManager.default.fileExists(atPath: full) ? full : nil
        }
    }

    private var dbURL: URL { documentsDirectory.appendingPathComponent("aurora_database.json") }
    private var documentsDirectory: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] }

    private func load() -> Payload {
        guard let data = try? Data(contentsOf: dbURL) else { return Payload(games: [], biosPaths: [:]) }
        return (try? JSONDecoder().decode(Payload.self, from: data)) ?? Payload(games: [], biosPaths: [:])
    }

    private func save() { if let d = try? JSONEncoder().encode(payload) { try? d.write(to: dbURL, options: .atomic) } }

    private func persistBIOS(at url: URL, key: SwiftBIOSKey) -> String? {
        guard url.isFileURL else { return nil }
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        let biosDir = documentsDirectory.appendingPathComponent("BIOS", isDirectory: true)
        try? FileManager.default.createDirectory(at: biosDir, withIntermediateDirectories: true)
        let dest = biosDir.appendingPathComponent("\(key.rawValue).\(url.pathExtension)")
        try? FileManager.default.removeItem(at: dest)
        do { try FileManager.default.copyItem(at: url, to: dest); return "BIOS/\(dest.lastPathComponent)" } catch { return nil }
    }
}
