import UIKit
import UniformTypeIdentifiers

private struct SwiftROMItem: Hashable {
    let id = UUID()
    let url: URL
    let title: String
    let coreType: EmulatorCoreType
    let subtitle: String
    let accentColor: UIColor
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
    private let romDirectoryName = "AuroraROMs"

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
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gearshape"), style: .plain, target: self, action: #selector(showSettings))

        searchController.searchBar.placeholder = "ゲーム検索"
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.register(SwiftROMCardCell.self, forCellWithReuseIdentifier: SwiftROMCardCell.reuseIdentifier)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
        let alert = UIAlertController(title: "Aurora Swift", message: "設定画面は次フェーズで追加予定です。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
        if keyword.isEmpty {
            filteredItems = allItems
        } else {
            filteredItems = allItems.filter { $0.title.localizedCaseInsensitiveContains(keyword) }
        }

        var snapshot = NSDiffableDataSourceSnapshot<Int, UUID>()
        snapshot.appendSections([0])
        snapshot.appendItems(filteredItems.map(\.id), toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func loadROMItems() -> [SwiftROMItem] {
        let fm = FileManager.default
        let folder = romFolderURL()
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)

        guard let files = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) else {
            return []
        }

        return files.compactMap { fileURL in
            guard let coreType = coreType(for: fileURL) else { return nil }
            let ext = fileURL.pathExtension.lowercased()
            return SwiftROMItem(
                url: fileURL,
                title: fileURL.deletingPathExtension().lastPathComponent,
                coreType: coreType,
                subtitle: ext,
                accentColor: color(for: coreType)
            )
        }.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    private func romFolderURL() -> URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent(romDirectoryName, isDirectory: true)
    }

    private func coreType(for url: URL) -> EmulatorCoreType? {
        switch url.pathExtension.lowercased() {
        case "gba":
            return EMULATOR_CORE_TYPE_GBA
        case "nds":
            return EMULATOR_CORE_TYPE_NDS
        case "nes":
            return EMULATOR_CORE_TYPE_NES
        case "gb", "gbc":
            return EMULATOR_CORE_TYPE_GB
        default:
            return nil
        }
    }

    private func color(for coreType: EmulatorCoreType) -> UIColor {
        switch coreType {
        case EMULATOR_CORE_TYPE_NDS: return .systemTeal
        case EMULATOR_CORE_TYPE_GBA: return .systemPurple
        case EMULATOR_CORE_TYPE_NES: return .systemRed
        case EMULATOR_CORE_TYPE_GB: return .systemGreen
        default: return .systemBlue
        }
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let fm = FileManager.default
        let targetFolder = romFolderURL()
        try? fm.createDirectory(at: targetFolder, withIntermediateDirectories: true)

        for sourceURL in urls {
            guard coreType(for: sourceURL) != nil else { continue }
            let destURL = targetFolder.appendingPathComponent(sourceURL.lastPathComponent)
            try? fm.removeItem(at: destURL)
            do {
                try fm.copyItem(at: sourceURL, to: destURL)
            } catch {
                print("[AUR][Swift] ROM import failed: \(error)")
            }
        }

        reloadLibrary()
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
        let vc = AUREmulatorViewController(romURL: item.url, coreType: item.coreType)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}
