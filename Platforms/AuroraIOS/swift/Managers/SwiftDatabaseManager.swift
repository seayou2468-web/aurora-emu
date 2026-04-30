import Foundation

enum SwiftBIOSKey: String, Codable, CaseIterable, Sendable {
    case ndsArm9 = "nds_arm9"
    case ndsArm7 = "nds_arm7"
    case ndsFirmware = "nds_firmware"
    case gba
    case gb
    case gbc
}

@MainActor final class SwiftDatabaseManager {
    static let shared = SwiftDatabaseManager()

    private struct Payload: Codable {
        var games: [SwiftROMItem]
        var biosPaths: [SwiftBIOSKey: String]
    }

    private var payload: Payload

    private init() {
        self.payload = SwiftDatabaseManager.staticLoad()
    }

    func games() -> [SwiftROMItem] {
        return payload.games
    }

    func upsertGame(_ game: SwiftROMItem) {
        if let i = payload.games.firstIndex(where: { $0.url == game.url }) {
            payload.games[i] = game
        } else {
            payload.games.append(game)
        }
        save()
    }

    func removeGame(id: UUID, removeROMFile: Bool) {
        guard let i = payload.games.firstIndex(where: { $0.id == id }) else { return }
        let target = payload.games.remove(at: i)
        if removeROMFile { try? FileManager.default.removeItem(at: target.url) }
        save()
    }

    private static var dbURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("aurora_database.json")
    }

    private static func staticLoad() -> Payload {
        guard let data = try? Data(contentsOf: dbURL) else { return Payload(games: [], biosPaths: [:]) }
        return (try? JSONDecoder().decode(Payload.self, from: data)) ?? Payload(games: [], biosPaths: [:])
    }

    private func save() {
        if let d = try? JSONEncoder().encode(payload) {
            try? d.write(to: SwiftDatabaseManager.dbURL, options: .atomic)
        }
    }
}
