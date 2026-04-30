import Foundation
import GameController

protocol SwiftExternalControllerDelegate: AnyObject {
    func externalControllerDidChange(key: EmulatorKey, pressed: Bool)
}

@MainActor final class SwiftExternalControllerManager {
    static let shared = SwiftExternalControllerManager()
    weak var delegate: SwiftExternalControllerDelegate?
    private var monitoring = false
    private init() {}
    func startMonitoring() {
        guard !monitoring else { return }
        monitoring = true
        NotificationCenter.default.addObserver(self, selector: #selector(controllerDidConnect), name: .GCControllerDidConnect, object: nil)
        GCController.controllers().forEach(setupController)
    }
    @objc private func controllerDidConnect(_ note: Notification) {
        if let c = note.object as? GCController { setupController(c) }
    }
    private func setupController(_ controller: GCController) {
        guard let p = controller.extendedGamepad else { return }
        p.buttonA.pressedChangedHandler = { [weak self] _,_,pressed in Task { @MainActor in self?.delegate?.externalControllerDidChange(key: EMULATOR_KEY_A, pressed: pressed) } }
        p.buttonB.pressedChangedHandler = { [weak self] _,_,pressed in Task { @MainActor in self?.delegate?.externalControllerDidChange(key: EMULATOR_KEY_B, pressed: pressed) } }
        p.leftShoulder.pressedChangedHandler = { [weak self] _,_,pressed in Task { @MainActor in self?.delegate?.externalControllerDidChange(key: EMULATOR_KEY_L, pressed: pressed) } }
        p.rightShoulder.pressedChangedHandler = { [weak self] _,_,pressed in Task { @MainActor in self?.delegate?.externalControllerDidChange(key: EMULATOR_KEY_R, pressed: pressed) } }
        p.buttonOptions?.pressedChangedHandler = { [weak self] _,_,pressed in Task { @MainActor in self?.delegate?.externalControllerDidChange(key: EMULATOR_KEY_SELECT, pressed: pressed) } }
        p.buttonMenu.pressedChangedHandler = { [weak self] _,_,pressed in Task { @MainActor in self?.delegate?.externalControllerDidChange(key: EMULATOR_KEY_START, pressed: pressed) } }
        p.dpad.up.pressedChangedHandler = { [weak self] _,_,pressed in Task { @MainActor in self?.delegate?.externalControllerDidChange(key: EMULATOR_KEY_UP, pressed: pressed) } }
        p.dpad.down.pressedChangedHandler = { [weak self] _,_,pressed in Task { @MainActor in self?.delegate?.externalControllerDidChange(key: EMULATOR_KEY_DOWN, pressed: pressed) } }
        p.dpad.left.pressedChangedHandler = { [weak self] _,_,pressed in Task { @MainActor in self?.delegate?.externalControllerDidChange(key: EMULATOR_KEY_LEFT, pressed: pressed) } }
        p.dpad.right.pressedChangedHandler = { [weak self] _,_,pressed in Task { @MainActor in self?.delegate?.externalControllerDidChange(key: EMULATOR_KEY_RIGHT, pressed: pressed) } }
    }
}
