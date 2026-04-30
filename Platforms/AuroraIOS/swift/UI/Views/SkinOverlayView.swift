import SwiftUI

struct SkinOverlayView: View {
    let skin: SwiftSkin
    let bridge: AuroraCoreBridge
    @State private var isLandscape: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let layout = isLandscape ? skin.landscape : skin.portrait
            let skinID = skin.id

            ZStack {
                // Background Image
                if let bgImage = SwiftSkinManager.shared.getSkinImage(skinID: skinID, imageName: layout.backgroundImage) {
                    Image(uiImage: bgImage)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                } else {
                    Color.black.ignoresSafeArea()
                }

                // Screen Area (Where the emulator video goes)
                let screenRect = CGRect(x: layout.screen.x * geometry.size.width,
                                        y: layout.screen.y * geometry.size.height,
                                        width: layout.screen.width * geometry.size.width,
                                        height: layout.screen.height * geometry.size.height)

                MetalVideoView(bridge: bridge)
                    .frame(width: screenRect.width, height: screenRect.height)
                    .position(x: screenRect.midX, y: screenRect.midY)

                // Buttons
                ForEach(layout.buttons, id: \.id) { button in
                    Button(action: {}) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.001)) // Invisible but tappable
                    }
                    .frame(width: button.width * geometry.size.width,
                           height: button.height * geometry.size.height)
                    .position(x: (button.x + button.width / 2) * geometry.size.width,
                              y: (button.y + button.height / 2) * geometry.size.height)
                    .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                        bridge.setKey(EmulatorKey(rawValue: UInt32(button.key)), pressed: pressing)
                    }, perform: {})
                }
            }
            .onAppear {
                updateOrientation(geometry: geometry)
            }
            .onChange(of: geometry.size) { oldValue, newValue in
                updateOrientation(geometry: geometry)
            }
        }
    }

    private func updateOrientation(geometry: GeometryProxy) {
        isLandscape = geometry.size.width > geometry.size.height
    }
}
