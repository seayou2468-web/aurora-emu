import UIKit

final class SwiftEmulatorViewController: UIViewController {
    private let romURL: URL
    private let coreType: EmulatorCoreType
    private var core: AuroraCoreBridge?

    init(romURL: URL, coreType: EmulatorCoreType) {
        self.romURL = romURL
        self.coreType = coreType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        title = romURL.deletingPathExtension().lastPathComponent

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = "エミュレータ初期化中..."
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])

        guard let core = AuroraCoreBridge(coreType: coreType) else {
            label.text = "コア初期化に失敗しました"
            return
        }
        self.core = core
        label.text = core.loadROM(url: romURL) ? "ROMをロードしました" : "ROMロードに失敗しました"
    }
}
