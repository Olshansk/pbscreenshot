import Foundation
@preconcurrency import KeyboardShortcuts
import PBScreenshotKit
import PBScreenshotMacOS

/// Global hotkeys.
///
/// These go through Carbon's `RegisterEventHotKey` (what KeyboardShortcuts wraps),
/// **not** a CGEvent tap. That choice is why this app needs no Accessibility
/// permission: it installs and works immediately, and it cannot be silently
/// broken by a stale TCC grant the way an event tap can.
extension KeyboardShortcuts.Name {
    static let captureRegion = Self(
        "captureRegion",
        default: .init(.two, modifiers: [.command, .shift])
    )
    static let captureFullScreen = Self("captureFullScreen")
}

enum Hotkeys {
    @MainActor
    static func setEnabled(_ enabled: Bool) {
        KeyboardShortcuts.isEnabled = enabled
    }

    @MainActor
    static func register() {
        KeyboardShortcuts.onKeyUp(for: .captureRegion) {
            CaptureService.shared.capture(mode: .interactive)
        }
        KeyboardShortcuts.onKeyUp(for: .captureFullScreen) {
            CaptureService.shared.capture(mode: .full)
        }
        setEnabled(UserDefaults.standard.object(forKey: DefaultsKey.isEnabled) as? Bool ?? true)
        PBLog.agent.debug("Hotkeys registered")
    }
}
