import Foundation

final class SwiftSkinManager {
    static let shared = SwiftSkinManager()
    private let queue = DispatchQueue(label: "aurora.skin.queue", qos: .userInitiated)
    private let url: URL
    private var selected: [String: SwiftSkin] = [:]

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        url = docs.appendingPathComponent("aurora_skins.json")
        if let d = try? Data(contentsOf: url), let s = try? JSONDecoder().decode([String: SwiftSkin].self, from: d) { selected = s }
    }

    func skin(for systemID: String) -> SwiftSkin { queue.sync { selected[systemID] ?? .default } }
    func setSkin(_ skin: SwiftSkin, for systemID: String) { queue.sync { selected[systemID] = skin; save() } }
    func resetSkin(for systemID: String) { queue.sync { selected.removeValue(forKey: systemID); save() } }

    private func save() {
        guard let data = try? JSONEncoder().encode(selected) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
