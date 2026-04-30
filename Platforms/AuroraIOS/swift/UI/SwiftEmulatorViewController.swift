import UIKit

final class SwiftEmulatorViewController: UIViewController, SwiftExternalControllerDelegate {
    private let romURL: URL
    private let coreType: EmulatorCoreType
    private var core: AuroraCoreBridge?
    private let overlayView = SwiftControllerOverlayView()

    init(romURL: URL, coreType: EmulatorCoreType) {
        self.romURL = romURL
        self.coreType = coreType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        title = romURL.deletingPathExtension().lastPathComponent

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = "エミュレータ初期化中..."
        view.addSubview(label)
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        guard let core = AuroraCoreBridge(coreType: coreType) else { label.text = "コア初期化に失敗しました"; return }
        self.core = core
        SwiftExternalControllerManager.shared.delegate = self
        SwiftExternalControllerManager.shared.startMonitoring()
        let systemID = String(coreType.rawValue)
        overlayView.apply(skin: SwiftSkinManager.shared.skin(for: systemID))
        label.text = core.loadROM(url: romURL) ? "ROMをロードしました" : "ROMロードに失敗しました"
    }

    func externalControllerDidChange(key: EmulatorKey, pressed: Bool) {
        core?.setKey(key, pressed: pressed)
    }
}
