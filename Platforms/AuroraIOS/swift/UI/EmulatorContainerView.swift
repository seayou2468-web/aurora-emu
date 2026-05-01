import SwiftUI

struct EmulatorContainerView: View {
    let item: SwiftROMItem
    @State private var bridge: AuroraCoreBridge?
    @State private var isShowingSaves = false
    @State private var activeSkin: SwiftSkin = .default
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            if let bridge = bridge {
                SkinOverlayView(skin: activeSkin, bridge: bridge)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
                ProgressView("Initializing Core...")
                    .tint(.white)
            }

            // HUD / Menu Button
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3.bold())
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    Spacer()
                    Button(action: { isShowingSaves = true }) {
                        Image(systemName: "tray.full.fill")
                            .font(.title3.bold())
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding()
                Spacer()
            }
        }
        .onAppear {
            SwiftSkinManager.shared.loadSkins()
            activeSkin = SwiftSkinManager.shared.availableSkins.first ?? .default
            bridge = AuroraCoreBridge(coreType: item.coreType)
            _ = bridge?.loadROM(url: item.url)
        }
        .sheet(isPresented: $isShowingSaves) {
            SaveStateMenuView(gameTitle: item.title, bridge: bridge)
                .presentationDetents([.medium, .large])
                .preferredColorScheme(.dark)
        }
    }
}

struct SaveStateMenuView: View {
    let gameTitle: String
    let bridge: AuroraCoreBridge?

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassView()
                List(0..<10) { slot in
                    SaveStateSlotRow(slot: slot, gameTitle: gameTitle, bridge: bridge)
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Save States")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SaveStateSlotRow: View {
    let slot: Int
    let gameTitle: String
    let bridge: AuroraCoreBridge?

    @State private var metadata: SaveStateMetadata?
    @State private var screenshot: UIImage?

    var body: some View {
        HStack {
            if let screenshot = screenshot {
                Image(uiImage: screenshot)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 75)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2), lineWidth: 1))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 100, height: 75)
                    .overlay(Text("Empty").font(.caption).foregroundColor(.gray))
            }

            VStack(alignment: .leading) {
                Text("Slot \(slot + 1)")
                    .font(.headline)
                if let meta = metadata {
                    Text(meta.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(meta.date, style: .time)
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Text("No data")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            HStack(spacing: 15) {
                Button(action: save) {
                    Image(systemName: "arrow.down.doc.fill")
                        .foregroundColor(.indigo)
                }
                .disabled(bridge == nil)

                Button(action: load) {
                    Image(systemName: "arrow.up.doc.fill")
                        .foregroundColor(.green)
                }
                .disabled(metadata == nil || bridge == nil)
            }
            .buttonStyle(.plain)
            .font(.title3)
        }
        .padding(.vertical, 8)
        .onAppear(perform: refresh)
    }

    private func refresh() {
        metadata = SaveStateManager.shared.getMetadata(slot: slot, gameTitle: gameTitle)
        screenshot = SaveStateManager.shared.getScreenshot(slot: slot, gameTitle: gameTitle)
    }

    private func save() {
        guard let bridge = bridge, let data = bridge.saveState() else { return }
        let shot = bridge.currentFrameImage()
        SaveStateManager.shared.save(data: data, screenshot: shot, slot: slot, gameTitle: gameTitle)
        refresh()
    }

    private func load() {
        guard let bridge = bridge, let data = SaveStateManager.shared.load(slot: slot, gameTitle: gameTitle) else { return }
        _ = bridge.loadState(data: data)
    }
}
