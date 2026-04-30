import UIKit

final class AuroraCompatRootViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "AuroraIOSApp (SwiftPM)"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center

        let detail = UILabel()
        detail.translatesAutoresizingMaskIntoConstraints = false
        detail.text = "SwiftPMビルド確認用エントリ"
        detail.numberOfLines = 0
        detail.textAlignment = .center
        detail.textColor = .secondaryLabel

        view.addSubview(label)
        view.addSubview(detail)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -16),
            detail.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 12),
            detail.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
}
