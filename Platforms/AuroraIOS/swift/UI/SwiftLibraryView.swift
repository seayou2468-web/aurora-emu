import SwiftUI
import UniformTypeIdentifiers

struct SwiftLibraryView: View {
    enum LibraryFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case gba = "GBA"
        case nes = "NES"
        case gb = "GB"
        case nds = "NDS"
        var id: String { rawValue }
    }

    enum SortMode: String, CaseIterable, Identifiable {
        case recentlyAdded = "Recently Added"
        case title = "Title"
        case fileSize = "File Size"
        var id: String { rawValue }
    }

    @State private var searchText = ""
    @State private var items: [SwiftROMItem] = []
    @State private var isShowingPicker = false
    @State private var selectedItem: SwiftROMItem?
    @State private var showSettings = false
    @State private var importError: String?
    @State private var libraryFilter: LibraryFilter = .all
    @State private var sortMode: SortMode = .recentlyAdded

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassView()

                if items.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.linearGradient(colors: [.purple, .indigo], startPoint: .top, endPoint: .bottom))
                        Text("No Games Found")
                            .font(.title2.bold())
                        Button("Import ROM") { isShowingPicker = true }
                            .buttonStyle(.borderedProminent)
                            .tint(.indigo)
                    }
                } else {
                    VStack(spacing: 10) {
                        Picker("Core", selection: $libraryFilter) {
                            ForEach(LibraryFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        List(sortedAndFilteredItems) { item in
                            ROMRowView(item: item)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedItem = item }
                        }
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { isShowingPicker = true }) {
                            Image(systemName: "plus")
                                .font(.title.bold())
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)))
                                .shadow(color: .purple.opacity(0.5), radius: 10)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Aurora Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort", selection: $sortMode) {
                            ForEach(SortMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        Button {
                            showSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .searchable(text: $searchText)
            .sheet(item: $selectedItem) { item in
                EmulatorContainerView(item: item)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showSettings) {
                AuroraSettingsView()
            }
            .fileImporter(isPresented: $isShowingPicker, allowedContentTypes: [.data], allowsMultipleSelection: true) { result in
                if case .success(let urls) = result { importROMs(urls: urls) }
            }
            .alert("Import Error", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } }), actions: {
                Button("OK") { importError = nil }
            }, message: {
                Text(importError ?? "")
            })
        }
        .onAppear { loadLibrary() }
    }

    var sortedAndFilteredItems: [SwiftROMItem] {
        let scoped = items.filter { item in
            switch libraryFilter {
            case .all: return true
            case .gba: return item.coreType == EMULATOR_CORE_TYPE_GBA
            case .nes: return item.coreType == EMULATOR_CORE_TYPE_NES
            case .gb: return item.coreType == EMULATOR_CORE_TYPE_GB
            case .nds: return item.coreType == EMULATOR_CORE_TYPE_NDS
            }
        }.filter { item in
            searchText.isEmpty || item.title.localizedCaseInsensitiveContains(searchText)
        }

        switch sortMode {
        case .recentlyAdded:
            return scoped.sorted { $0.addedDate > $1.addedDate }
        case .title:
            return scoped.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .fileSize:
            return scoped.sorted { $0.fileSizeBytes > $1.fileSizeBytes }
        }
    }

    private func romFolderURL() -> URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("ROMs", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @MainActor func loadLibrary() {
        let folder = romFolderURL()
        guard let files = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]) else { return }
        items = files.compactMap { url in
            let ext = url.pathExtension.lowercased()
            let type: EmulatorCoreType
            switch ext {
            case "nds", "srl", "dsi": type = EMULATOR_CORE_TYPE_NDS
            case "gba": type = EMULATOR_CORE_TYPE_GBA
            case "gb", "gbc": type = EMULATOR_CORE_TYPE_GB
            case "nes", "fds": type = EMULATOR_CORE_TYPE_NES
            default: return nil
            }
            let rv = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
            return SwiftROMItem(id: UUID(), url: url, title: url.deletingPathExtension().lastPathComponent, launchTarget: "core", extensionLabel: ext, coreType: type, addedDate: rv?.contentModificationDate ?? Date(), fileSizeBytes: Int64(rv?.fileSize ?? 0))
        }
    }

    @MainActor func importROMs(urls: [URL]) {
        let target = romFolderURL()
        var copied = 0
        var failures: [String] = []
        for src in urls {
            let access = src.startAccessingSecurityScopedResource()
            defer {
                if access { src.stopAccessingSecurityScopedResource() }
            }
            let ext = src.pathExtension.lowercased()
            guard ["gba", "gb", "gbc", "nes", "fds", "nds", "srl", "dsi"].contains(ext) else {
                failures.append("\(src.lastPathComponent): unsupported format")
                continue
            }
            do {
                let dst = target.appendingPathComponent(src.lastPathComponent)
                if FileManager.default.fileExists(atPath: dst.path) {
                    try FileManager.default.removeItem(at: dst)
                }
                try FileManager.default.copyItem(at: src, to: dst)
                copied += 1
            } catch {
                failures.append("\(src.lastPathComponent): \(error.localizedDescription)")
            }
        }
        if copied == 0, !failures.isEmpty {
            importError = failures.joined(separator: "\n")
        }
        loadLibrary()
    }
}

struct ROMCardView: View {
    let item: SwiftROMItem
    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 200)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                Text(item.extensionLabel.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(item.accentColor.opacity(0.8))
                    .foregroundColor(.white).cornerRadius(6).padding(8)
            }
            Text(item.title).font(.subheadline.bold()).foregroundColor(.white).lineLimit(1).padding(.horizontal, 4)
        }
    }
}

struct ROMRowView: View {
    let item: SwiftROMItem

    private var fileSizeLabel: String {
        ByteCountFormatter.string(fromByteCount: item.fileSizeBytes, countStyle: .file)
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(item.accentColor.opacity(0.25))
                .frame(width: 42, height: 42)
                .overlay(Text(item.extensionLabel.uppercased()).font(.caption2.bold()))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title).font(.headline)
                Text("\(item.extensionLabel.uppercased()) • \(fileSizeLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}
