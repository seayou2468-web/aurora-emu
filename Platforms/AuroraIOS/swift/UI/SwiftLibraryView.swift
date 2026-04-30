import SwiftUI
import UniformTypeIdentifiers

struct SwiftLibraryView: View {
    @State private var searchText = ""
    @State private var items: [SwiftROMItem] = []
    @State private var isShowingPicker = false
    @State private var selectedItem: SwiftROMItem?

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
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 20) {
                            ForEach(filteredItems) { item in
                                ROMCardView(item: item)
                                    .onTapGesture { selectedItem = item }
                            }
                        }
                        .padding()
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
            .searchable(text: $searchText)
            .sheet(item: $selectedItem) { item in
                EmulatorContainerView(item: item)
                    .ignoresSafeArea()
            }
            .fileImporter(isPresented: $isShowingPicker, allowedContentTypes: [.data], allowsMultipleSelection: true) { result in
                if case .success(let urls) = result { importROMs(urls: urls) }
            }
        }
        .onAppear { loadLibrary() }
    }

    var filteredItems: [SwiftROMItem] {
        searchText.isEmpty ? items : items.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
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
        for src in urls {
            let dst = target.appendingPathComponent(src.lastPathComponent)
            try? FileManager.default.removeItem(at: dst)
            try? FileManager.default.copyItem(at: src, to: dst)
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
