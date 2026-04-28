import UIKit

final class SwiftLibraryViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Aurora (Swift)"

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Swift版AuroraIOSを新規構築中"
        label.textColor = .secondaryLabel
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
