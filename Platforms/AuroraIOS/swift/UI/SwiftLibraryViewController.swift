import UIKit
import UniformTypeIdentifiers

private struct SwiftROMItem: Hashable {
    let id = UUID()
    let url: URL
    let title: String
    let launchTarget: SwiftLaunchTarget
    let subtitle: String
    let accentColor: UIColor
}

private enum SwiftLaunchTarget: Hashable {
    case standard(EmulatorCoreType)
    case aurora3ds
}

private enum SwiftSortMode {
    case name
    case recentlyAdded
}

private final class SwiftROMCardCell: UICollectionViewCell {
    static let reuseIdentifier = "SwiftROMCardCell"

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
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
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.82)
        coreLabel.font = .monospacedSystemFont(ofSize: 11, weight: .semibold)
        coreLabel.textColor = .white
        coreLabel.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        coreLabel.layer.cornerRadius = 10
        coreLabel.clipsToBounds = true
        coreLabel.textAlignment = .center
        playIcon.tintColor = .white
        playIcon.contentMode = .scaleAspectFit

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 6

        let topRow = UIStackView(arrangedSubviews: [coreLabel, UIView(), playIcon])
        topRow.alignment = .center

        let rootStack = UIStackView(arrangedSubviews: [topRow, textStack])
        rootStack.axis = .vertical
        rootStack.spacing = 16
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
        subtitleLabel.text = item.subtitle
        coreLabel.text = "  \(item.subtitle.uppercased())  "

        let gradient = CAGradientLayer()
        gradient.name = "AuroraGradient"
        gradient.frame = bounds
        gradient.colors = [
            item.accentColor.withAlphaComponent(0.68).cgColor,
            UIColor.black.withAlphaComponent(0.82).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        contentView.layer.insertSublayer(gradient, at: 0)
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
    private let filterControl = UISegmentedControl(items: ["All", "3DS/NDS", "GBA", "NES", "GB"])
    private let summaryLabel = UILabel()
    private let emptyStateLabel = UILabel()
    private let emptyImportButton = UIButton(type: .system)
    private let romDirectoryName = "AuroraROMs"
    private var sortMode: SwiftSortMode = .name

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        reloadLibrary()
    }

    private func configureUI() {
        title = "Aurora Swift"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .black

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.down"), style: .plain, target: self, action: #selector(importROM)),
            UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .plain, target: self, action: #selector(reloadLibrary))
        ]
        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle"), style: .plain, target: self, action: #selector(showSortMenu)),
            UIBarButtonItem(image: UIImage(systemName: "gearshape"), style: .plain, target: self, action: #selector(showSettings))
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

        emptyStateLabel.text = "ROMがありません。右上のインポートから追加してください。"
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateLabel)

        emptyImportButton.setTitle("ROMをインポート", for: .normal)
        emptyImportButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        emptyImportButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.25)
        emptyImportButton.tintColor = .white
        emptyImportButton.layer.cornerRadius = 12
        emptyImportButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        emptyImportButton.addTarget(self, action: #selector(importROM), for: .touchUpInside)
        emptyImportButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyImportButton)

        NSLayoutConstraint.activate([
            filterControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            filterControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filterControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            summaryLabel.topAnchor.constraint(equalTo: filterControl.bottomAnchor, constant: 10),
            summaryLabel.leadingAnchor.constraint(equalTo: filterControl.leadingAnchor, constant: 4),
            summaryLabel.trailingAnchor.constraint(equalTo: filterControl.trailingAnchor),

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

        dataSource = UICollectionViewDiffableDataSource<Int, UUID>(collectionView: collectionView) { [weak self] collectionView, indexPath, itemID in
            guard let self, let item = self.filteredItems.first(where: { $0.id == itemID }) else { return nil }
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SwiftROMCardCell.reuseIdentifier, for: indexPath) as? SwiftROMCardCell else {
                return nil
            }
            cell.configure(with: item)
            return cell
        }
    }

    private func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, env in
            let isWide = env.container.effectiveContentSize.width > 700
            let columns = isWide ? 2 : 1
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0 / CGFloat(columns)),
                                                  heightDimension: .absolute(140))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .absolute(140))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: columns)
            return NSCollectionLayoutSection(group: group)
        }
    }

    @objc private func showSettings() {
        let alert = UIAlertController(title: "Aurora Swift", message: "Swift UI Library Settings", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "ライブラリ再読み込み", style: .default) { [weak self] _ in
            self?.reloadLibrary()
        })
        alert.addAction(UIAlertAction(title: "検索をクリア", style: .default) { [weak self] _ in
            self?.searchController.searchBar.text = nil
            self?.applyFilter(searchText: nil)
        })
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.leftBarButtonItems?.last
        }
        present(alert, animated: true)
    }

    @objc private func showSortMenu() {
        let alert = UIAlertController(title: "並び順", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "名前順", style: .default) { [weak self] _ in
            self?.sortMode = .name
            self?.reloadLibrary()
        })
        alert.addAction(UIAlertAction(title: "最近追加順", style: .default) { [weak self] _ in
            self?.sortMode = .recentlyAdded
            self?.reloadLibrary()
        })
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.leftBarButtonItems?.first
        }
        present(alert, animated: true)
    }

    @objc private func filterChanged() {
        applyFilter(searchText: searchController.searchBar.text)
    }

    @objc private func importROM() {
        let supported: [UTType] = [.data]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supported, asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = true
        present(picker, animated: true)
    }

    @objc private func reloadLibrary() {
        allItems = loadROMItems()
        applyFilter(searchText: searchController.searchBar.text)
    }

    private func applyFilter(searchText: String?) {
        let keyword = (searchText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let filteredByCore = allItems.filter { item in
            switch filterControl.selectedSegmentIndex {
            case 1:
                switch item.launchTarget {
                case .aurora3ds: return true
                case .standard(let type): return type == EMULATOR_CORE_TYPE_NDS
                }
            case 2:
                if case .standard(let type) = item.launchTarget { return type == EMULATOR_CORE_TYPE_GBA }
                return false
            case 3:
                if case .standard(let type) = item.launchTarget { return type == EMULATOR_CORE_TYPE_NES }
                return false
            case 4:
                if case .standard(let type) = item.launchTarget { return type == EMULATOR_CORE_TYPE_GB }
                return false
            default: return true
            }
        }

        if keyword.isEmpty {
            filteredItems = filteredByCore
        } else {
            filteredItems = filteredByCore.filter { $0.title.localizedCaseInsensitiveContains(keyword) }
        }

        var snapshot = NSDiffableDataSourceSnapshot<Int, UUID>()
        snapshot.appendSections([0])
        snapshot.appendItems(filteredItems.map(\.id), toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: true)

        summaryLabel.text = "\(filteredItems.count) games ・ \(displaySortMode())"
        let isEmpty = filteredItems.isEmpty
        emptyStateLabel.isHidden = !isEmpty
        emptyImportButton.isHidden = !isEmpty
    }

    private func loadROMItems() -> [SwiftROMItem] {
        let fm = FileManager.default
        let folder = romFolderURL()
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)

        guard let files = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) else {
            return []
        }

        var items = files.compactMap { fileURL in
            guard let launchTarget = launchTarget(for: fileURL) else { return nil }
            let ext = fileURL.pathExtension.lowercased()
            return SwiftROMItem(
                url: fileURL,
                title: fileURL.deletingPathExtension().lastPathComponent,
                launchTarget: launchTarget,
                subtitle: ext,
                accentColor: color(for: launchTarget)
            )
        }

        switch sortMode {
        case .name:
            items.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .recentlyAdded:
            items.sort {
                let lhs = (try? $0.url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let rhs = (try? $1.url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return lhs > rhs
            }
        }
        return items
    }

    private func romFolderURL() -> URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent(romDirectoryName, isDirectory: true)
    }

    private func launchTarget(for url: URL) -> SwiftLaunchTarget? {
        switch url.pathExtension.lowercased() {
        case "gba":
            return .standard(EMULATOR_CORE_TYPE_GBA)
        case "nds":
            return .standard(EMULATOR_CORE_TYPE_NDS)
        case "nes":
            return .standard(EMULATOR_CORE_TYPE_NES)
        case "gb", "gbc":
            return .standard(EMULATOR_CORE_TYPE_GB)
        case "3ds", "3dsx", "cci", "cxi":
            return .aurora3ds
        default:
            return nil
        }
    }

    private func color(for launchTarget: SwiftLaunchTarget) -> UIColor {
        switch launchTarget {
        case .aurora3ds: return .systemOrange
        case .standard(let coreType):
            switch coreType {
            case EMULATOR_CORE_TYPE_NDS: return .systemTeal
            case EMULATOR_CORE_TYPE_GBA: return .systemPurple
            case EMULATOR_CORE_TYPE_NES: return .systemRed
            case EMULATOR_CORE_TYPE_GB: return .systemGreen
            default: return .systemBlue
            }
        }
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let fm = FileManager.default
        let targetFolder = romFolderURL()
        try? fm.createDirectory(at: targetFolder, withIntermediateDirectories: true)

        for sourceURL in urls {
            guard launchTarget(for: sourceURL) != nil else { continue }
            let destURL = targetFolder.appendingPathComponent(sourceURL.lastPathComponent)
            try? fm.removeItem(at: destURL)
            do {
                try fm.copyItem(at: sourceURL, to: destURL)
            } catch {
                showError(message: "ROM import failed: \(error.localizedDescription)")
            }
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        reloadLibrary()
    }

    private func displaySortMode() -> String {
        switch sortMode {
        case .name: return "Sort: Name"
        case .recentlyAdded: return "Sort: Recent"
        }
    }

    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension SwiftLibraryViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        applyFilter(searchText: searchController.searchBar.text)
    }
}

extension SwiftLibraryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard filteredItems.indices.contains(indexPath.item) else { return }
        let item = filteredItems[indexPath.item]
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switch item.launchTarget {
        case .aurora3ds:
            let vc = AUR3DSEmulatorViewController(romURL: item.url)
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        case .standard(let coreType):
            let vc = AUREmulatorViewController(romURL: item.url, coreType: coreType)
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        }
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard filteredItems.indices.contains(indexPath.item) else { return nil }
        let item = filteredItems[indexPath.item]
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let deleteAction = UIAction(title: "Delete ROM", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                do {
                    try FileManager.default.removeItem(at: item.url)
                    self?.reloadLibrary()
                } catch {
                    self?.showError(message: "Delete failed: \(error.localizedDescription)")
                }
            }
            return UIMenu(title: "", children: [deleteAction])
        }
    }
}
