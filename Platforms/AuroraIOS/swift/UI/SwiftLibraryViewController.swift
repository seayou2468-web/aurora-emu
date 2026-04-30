import UIKit
import UniformTypeIdentifiers

private struct SwiftROMItem: Hashable {
    let id = UUID()
    let url: URL
    let title: String
    let launchTarget: SwiftLaunchTarget
    let extensionLabel: String
    let coreType: EmulatorCoreType
    let accentColor: UIColor
    let addedDate: Date
    let fileSizeBytes: Int64
}

private enum SwiftLaunchTarget: Hashable {
    case coreSession
}

private enum SwiftSortMode: String, CaseIterable {
    case name = "名前順"
    case recentlyAdded = "追加日順"
    case fileSize = "サイズ順"
}

private enum SwiftLayoutMode: String {
    case compact = "コンパクト"
    case cozy = "標準"
    case poster = "ポスター"
}

private final class SwiftROMCardCell: UICollectionViewCell {
    static let reuseIdentifier = "SwiftROMCardCell"

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let metaLabel = UILabel()
    private let coreLabel = UILabel()
    private let playIcon = UIImageView(image: UIImage(systemName: "play.circle.fill"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        contentView.layer.cornerRadius = 20
        contentView.clipsToBounds = true

        blurView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(blurView)

        titleLabel.font = .systemFont(ofSize: 19, weight: .bold)
        titleLabel.textColor = .white
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.88)
        metaLabel.font = .monospacedSystemFont(ofSize: 11, weight: .medium)
        metaLabel.textColor = UIColor.white.withAlphaComponent(0.72)
        coreLabel.font = .monospacedSystemFont(ofSize: 11, weight: .semibold)
        coreLabel.textColor = .white
        coreLabel.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        coreLabel.layer.cornerRadius = 10
        coreLabel.clipsToBounds = true
        coreLabel.textAlignment = .center
        playIcon.tintColor = .white
        playIcon.contentMode = .scaleAspectFit

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, metaLabel])
        textStack.axis = .vertical
        textStack.spacing = 6

        let topRow = UIStackView(arrangedSubviews: [coreLabel, UIView(), playIcon])
        topRow.alignment = .center

        let rootStack = UIStackView(arrangedSubviews: [topRow, textStack])
        rootStack.axis = .vertical
        rootStack.spacing = 14
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        blurView.contentView.addSubview(rootStack)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: contentView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            rootStack.topAnchor.constraint(equalTo: blurView.contentView.topAnchor, constant: 16),
            rootStack.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 16),
            rootStack.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -16),
            rootStack.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor, constant: -16),

            coreLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 64),
            playIcon.widthAnchor.constraint(equalToConstant: 24),
            playIcon.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.layer.sublayers?.removeAll(where: { $0.name == "AuroraGradient" })
    }

    func configure(with item: SwiftROMItem) {
        titleLabel.text = item.title
        subtitleLabel.text = item.extensionLabel.uppercased()
        metaLabel.text = ByteCountFormatter.string(fromByteCount: item.fileSizeBytes, countStyle: .file)
        coreLabel.text = "  \(coreDisplayName(for: item.coreType))  "

        let gradient = CAGradientLayer()
        gradient.name = "AuroraGradient"
        gradient.frame = bounds
        gradient.colors = [item.accentColor.withAlphaComponent(0.68).cgColor, UIColor.black.withAlphaComponent(0.82).cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        contentView.layer.insertSublayer(gradient, at: 0)
    }

    private func coreDisplayName(for coreType: EmulatorCoreType) -> String {
        switch coreType {
        case EMULATOR_CORE_TYPE_NDS: return "NDS"
        case EMULATOR_CORE_TYPE_GBA: return "GBA"
        case EMULATOR_CORE_TYPE_GB: return "GB"
        case EMULATOR_CORE_TYPE_NES: return "NES"
        default: return "CORE"
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.sublayers?.first(where: { $0.name == "AuroraGradient" })?.frame = bounds
    }
}

final class SwiftLibraryViewController: UIViewController, UIDocumentPickerDelegate {
    private var allItems: [SwiftROMItem] = []
    private var filteredItems: [SwiftROMItem] = []
    private var dataSource: UICollectionViewDiffableDataSource<Int, UUID>!
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
    private lazy var searchController = UISearchController(searchResultsController: nil)
    private let filterControl = UISegmentedControl(items: ["All", "NDS", "GBA", "GB", "NES"])
    private let summaryLabel = UILabel()
    private let emptyStateLabel = UILabel()
    private let emptyImportButton = UIButton(type: .system)
    private let romDirectoryName = "AuroraROMs"
    private var sortMode: SwiftSortMode = .name
    private var layoutMode: SwiftLayoutMode = .cozy

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        reloadLibrary()
    }

    private func configureUI() {
        title = "Aurora Multi-Emu"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .black

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "plus.circle.fill"), style: .plain, target: self, action: #selector(importROM)),
            UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .plain, target: self, action: #selector(reloadLibrary))
        ]
        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "square.grid.2x2"), style: .plain, target: self, action: #selector(showLayoutMenu)),
            UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle"), style: .plain, target: self, action: #selector(showSortMenu)),
            UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: #selector(showSettings))
        ]

        searchController.searchBar.placeholder = "ゲーム検索"
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.register(SwiftROMCardCell.self, forCellWithReuseIdentifier: SwiftROMCardCell.reuseIdentifier)
        view.addSubview(collectionView)

        filterControl.selectedSegmentIndex = 0
        filterControl.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        filterControl.selectedSegmentTintColor = UIColor.systemCyan.withAlphaComponent(0.6)
        filterControl.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        filterControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(filterControl)

        summaryLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        summaryLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        summaryLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(summaryLabel)

        emptyStateLabel.text = "ROMがありません。右上の追加ボタンからインポートしてください。"
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateLabel)

        emptyImportButton.setTitle("ROMをインポート", for: .normal)
        emptyImportButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        emptyImportButton.tintColor = .white
        emptyImportButton.layer.cornerRadius = 12
        var buttonConfig = UIButton.Configuration.filled()
        buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        buttonConfig.baseBackgroundColor = UIColor.systemBlue.withAlphaComponent(0.25)
        buttonConfig.baseForegroundColor = .white
        emptyImportButton.configuration = buttonConfig
        emptyImportButton.addTarget(self, action: #selector(importROM), for: .touchUpInside)
        emptyImportButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyImportButton)

        NSLayoutConstraint.activate([
            filterControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            filterControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filterControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            summaryLabel.topAnchor.constraint(equalTo: filterControl.bottomAnchor, constant: 10),
            summaryLabel.leadingAnchor.constraint(equalTo: filterControl.leadingAnchor, constant: 4),
            collectionView.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            emptyImportButton.topAnchor.constraint(equalTo: emptyStateLabel.bottomAnchor, constant: 16),
            emptyImportButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        dataSource = UICollectionViewDiffableDataSource<Int, UUID>(collectionView: collectionView) { [weak self] cv, ip, id in
            guard let self, let item = self.filteredItems.first(where: { $0.id == id }) else { return nil }
            let cell = cv.dequeueReusableCell(withReuseIdentifier: SwiftROMCardCell.reuseIdentifier, for: ip) as? SwiftROMCardCell
            cell?.configure(with: item)
            return cell
        }
    }

    private func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, env in
            let width = env.container.effectiveContentSize.width
            let columns: Int
            let height: CGFloat
            switch self.layoutMode {
            case .compact: columns = width > 700 ? 3 : 2; height = 118
            case .cozy: columns = width > 700 ? 2 : 1; height = 142
            case .poster: columns = width > 700 ? 2 : 1; height = 188
            }
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0 / CGFloat(columns)), heightDimension: .absolute(height))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(height))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: columns)
            return NSCollectionLayoutSection(group: group)
        }
    }

    @objc private func showLayoutMenu() {
        let alert = UIAlertController(title: "表示密度", message: nil, preferredStyle: .actionSheet)
        for mode in [SwiftLayoutMode.compact, .cozy, .poster] {
            alert.addAction(UIAlertAction(title: mode.rawValue, style: .default) { [weak self] _ in
                self?.layoutMode = mode
                self?.collectionView.setCollectionViewLayout(self?.createLayout() ?? UICollectionViewFlowLayout(), animated: true)
            })
        }
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func showSettings() { reloadLibrary() }
    @objc private func showSortMenu() {
        let alert = UIAlertController(title: "並び順", message: nil, preferredStyle: .actionSheet)
        SwiftSortMode.allCases.forEach { mode in
            alert.addAction(UIAlertAction(title: mode.rawValue, style: .default) { [weak self] _ in self?.sortMode = mode; self?.reloadLibrary() })
        }
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        present(alert, animated: true)
    }
    @objc private func filterChanged() { applyFilter(searchText: searchController.searchBar.text) }
    @objc private func importROM() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: true)
        picker.delegate = self; picker.allowsMultipleSelection = true; present(picker, animated: true)
    }
    @objc private func reloadLibrary() { allItems = loadROMItems(); applyFilter(searchText: searchController.searchBar.text) }

    private func applyFilter(searchText: String?) {
        let keyword = (searchText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let filteredByCore = allItems.filter { item in
            switch filterControl.selectedSegmentIndex {
            case 1: return item.coreType == EMULATOR_CORE_TYPE_NDS
            case 2: return item.coreType == EMULATOR_CORE_TYPE_GBA
            case 3: return item.coreType == EMULATOR_CORE_TYPE_GB
            case 4: return item.coreType == EMULATOR_CORE_TYPE_NES
            default: return true
            }
        }
        filteredItems = keyword.isEmpty ? filteredByCore : filteredByCore.filter { $0.title.localizedCaseInsensitiveContains(keyword) }
        var snapshot = NSDiffableDataSourceSnapshot<Int, UUID>()
        snapshot.appendSections([0]); snapshot.appendItems(filteredItems.map(\.id), toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: true)
        summaryLabel.text = "\(filteredItems.count)件 / 全\(allItems.count)件 ・ \(sortMode.rawValue)"
        emptyStateLabel.isHidden = !filteredItems.isEmpty
        emptyImportButton.isHidden = !filteredItems.isEmpty
    }

    private func loadROMItems() -> [SwiftROMItem] {
        let folder = romFolderURL(); try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        guard let files = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey], options: [.skipsHiddenFiles]) else { return [] }
        var items = files.compactMap { url -> SwiftROMItem? in
            guard let launchTarget = launchTarget(for: url) else { return nil }
            let rv = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
            return SwiftROMItem(url: url, title: url.deletingPathExtension().lastPathComponent, launchTarget: launchTarget, extensionLabel: url.pathExtension.lowercased(), coreType: coreType(for: url), accentColor: color(for: coreType(for: url)), addedDate: rv?.contentModificationDate ?? .distantPast, fileSizeBytes: Int64(rv?.fileSize ?? 0))
        }
        switch sortMode {
        case .name: items.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .recentlyAdded: items.sort { $0.addedDate > $1.addedDate }
        case .fileSize: items.sort { $0.fileSizeBytes > $1.fileSizeBytes }
        }
        return items
    }

    private func romFolderURL() -> URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(romDirectoryName, isDirectory: true) }
    private func launchTarget(for url: URL) -> SwiftLaunchTarget? { ["nds","srl","dsi","gba","gb","gbc","nes","fds"].contains(url.pathExtension.lowercased()) ? .coreSession : nil }
    private func coreType(for url: URL) -> EmulatorCoreType {
        switch url.pathExtension.lowercased() { case "nds", "srl", "dsi": return EMULATOR_CORE_TYPE_NDS; case "gba": return EMULATOR_CORE_TYPE_GBA; case "gb", "gbc": return EMULATOR_CORE_TYPE_GB; case "nes", "fds": return EMULATOR_CORE_TYPE_NES; default: return EMULATOR_CORE_TYPE_NDS }
    }
    private func color(for coreType: EmulatorCoreType) -> UIColor {
        switch coreType { case EMULATOR_CORE_TYPE_NDS: return .systemIndigo; case EMULATOR_CORE_TYPE_GBA: return .systemPurple; case EMULATOR_CORE_TYPE_GB: return .systemGreen; case EMULATOR_CORE_TYPE_NES: return .systemRed; default: return .gray }
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let target = romFolderURL(); try? FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        for src in urls where launchTarget(for: src) != nil {
            let dst = target.appendingPathComponent(src.lastPathComponent)
            try? FileManager.default.removeItem(at: dst)
            do { try FileManager.default.copyItem(at: src, to: dst) } catch { showError(message: "ROM import failed: \(error.localizedDescription)") }
        }
        reloadLibrary()
    }

    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default)); present(alert, animated: true)
    }
}

extension SwiftLibraryViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) { applyFilter(searchText: searchController.searchBar.text) }
}

extension SwiftLibraryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard filteredItems.indices.contains(indexPath.item) else { return }
        let item = filteredItems[indexPath.item]
        let vc = AUREmulatorViewController(romurl: item.url, coreType: item.coreType)
        vc.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        present(vc, animated: true)
    }
}
