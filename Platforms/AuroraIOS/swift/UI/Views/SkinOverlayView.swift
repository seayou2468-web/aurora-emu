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
                if let bgImage = SwiftSkinManager.shared.getSkinImage(skinID: skinID, imageName: layout.backgroundImage) {
                    Image(uiImage: bgImage).resizable().scaledToFill().ignoresSafeArea()
                } else {
                    Color.black.ignoresSafeArea()
                }
                let screenRect = CGRect(x: layout.screen.x * geometry.size.width,
                                        y: layout.screen.y * geometry.size.height,
                                        width: layout.screen.width * geometry.size.width,
                                        height: layout.screen.height * geometry.size.height)
                MetalVideoView(bridge: bridge)
                    .frame(width: screenRect.width, height: screenRect.height)
                    .position(x: screenRect.midX, y: screenRect.midY)
                ForEach(layout.buttons, id: \.id) { button in
                    Button(action: {}) {
                        ZStack {
                            Group {
                                if button.style == "face" {
                                    Circle().fill(Color.white.opacity(0.18))
                                    Circle().stroke(Color.white.opacity(0.35), lineWidth: 1)
                                } else if button.style == "dpad" {
                                    RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.18))
                                    RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.35), lineWidth: 1)
                                } else {
                                    Capsule().fill(Color.white.opacity(0.14))
                                    Capsule().stroke(Color.white.opacity(0.35), lineWidth: 1)
                                }
                            }
                            Text((button.title ?? button.id).uppercased())
                                .font(.caption2.bold())
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .frame(width: button.width * geometry.size.width, height: button.height * geometry.size.height)
                    .position(x: (button.x + button.width / 2) * geometry.size.width, y: (button.y + button.height / 2) * geometry.size.height)
                    .onLongPressGesture(minimumDuration: 0) { } onPressingChanged: { pressing in
                        guard let raw = button.key else { return }
                        bridge.setKey(EmulatorKey(rawValue: UInt32(raw)), pressed: pressing)
                    }
                }
            }
            .onAppear { isLandscape = geometry.size.width > geometry.size.height }
            .onChange(of: geometry.size) { oldValue, newValue in isLandscape = newValue.width > newValue.height }
        }
    }
}
