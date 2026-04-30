import UIKit

final class SwiftSkinSettingsViewController: UITableViewController {
    private let systemID: String
    private let choices: [SwiftSkin] = [
        .default,
        SwiftSkin(id: "minimal", name: "Minimal", overlayImageName: nil, opacity: 0.9),
        SwiftSkin(id: "ghost", name: "Ghost", overlayImageName: nil, opacity: 0.7)
    ]

    init(systemID: String) {
        self.systemID = systemID
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "スキン設定"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { choices.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let skin = choices[indexPath.row]
        let current = SwiftSkinManager.shared.skin(for: systemID)
        cell.textLabel?.text = skin.name
        cell.detailTextLabel?.text = "opacity: \(skin.opacity)"
        cell.accessoryType = current.id == skin.id ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        SwiftSkinManager.shared.setSkin(choices[indexPath.row], for: systemID)
        navigationController?.popViewController(animated: true)
    }
}
