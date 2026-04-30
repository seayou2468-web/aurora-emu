import Foundation
import GameController

protocol SwiftExternalControllerDelegate: AnyObject {
    func externalControllerDidChange(key: EmulatorKey, pressed: Bool)
}

final class SwiftExternalControllerManager {
    static let shared = SwiftExternalControllerManager()
    weak var delegate: SwiftExternalControllerDelegate?
    private var monitoring = false

    private init() {}

    func startMonitoring() {
        guard !monitoring else { return }
        monitoring = true
        NotificationCenter.default.addObserver(self, selector: #selector(controllerDidConnect(_:)), name: .GCControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(controllerDidDisconnect(_:)), name: .GCControllerDidDisconnect, object: nil)
        GCController.controllers().forEach(setupController)
    }

    @objc private func controllerDidConnect(_ note: Notification) {
        guard let c = note.object as? GCController else { return }
        setupController(c)
    }

    @objc private func controllerDidDisconnect(_ note: Notification) {}

    private func setupController(_ controller: GCController) {
        guard let p = controller.extendedGamepad else { return }
        p.buttonA.pressedChangedHandler = { [weak self] _,_,pressed in self?.emit(.EMULATOR_KEY_A, pressed) }
        p.buttonB.pressedChangedHandler = { [weak self] _,_,pressed in self?.emit(.EMULATOR_KEY_B, pressed) }
        p.leftShoulder.pressedChangedHandler = { [weak self] _,_,pressed in self?.emit(.EMULATOR_KEY_L, pressed) }
        p.rightShoulder.pressedChangedHandler = { [weak self] _,_,pressed in self?.emit(.EMULATOR_KEY_R, pressed) }
        p.buttonOptions?.pressedChangedHandler = { [weak self] _,_,pressed in self?.emit(.EMULATOR_KEY_SELECT, pressed) }
        p.buttonMenu.pressedChangedHandler = { [weak self] _,_,pressed in self?.emit(.EMULATOR_KEY_START, pressed) }
        p.dpad.up.pressedChangedHandler = { [weak self] _,_,pressed in self?.emit(.EMULATOR_KEY_UP, pressed) }
        p.dpad.down.pressedChangedHandler = { [weak self] _,_,pressed in self?.emit(.EMULATOR_KEY_DOWN, pressed) }
        p.dpad.left.pressedChangedHandler = { [weak self] _,_,pressed in self?.emit(.EMULATOR_KEY_LEFT, pressed) }
        p.dpad.right.pressedChangedHandler = { [weak self] _,_,pressed in self?.emit(.EMULATOR_KEY_RIGHT, pressed) }
    }

    private func emit(_ key: EmulatorKey, _ pressed: Bool) {
        delegate?.externalControllerDidChange(key: key, pressed: pressed)
    }
}
