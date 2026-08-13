import AppKit
import PBScreenshotKit
import SwiftUI

/// UserDefaults keys shared between the service and the settings UI.
enum DefaultsKey {
    static let clipboardMode = "clipboardMode"
    static let retentionHours = "retentionHours"
    static let silentShutter = "silentShutter"
}

/// Runs captures on behalf of the menu and the hotkey.
@MainActor
final class CaptureService {
    static let shared = CaptureService()

    private let defaults = UserDefaults.standard

    private init() {
        defaults.register(defaults: [
            DefaultsKey.clipboardMode: ClipboardMode.fileURL.rawValue,
            DefaultsKey.retentionHours: 1.0,
            DefaultsKey.silentShutter: false,
        ])
    }

    var clipboardMode: ClipboardMode {
        ClipboardMode(rawValue: defaults.string(forKey: DefaultsKey.clipboardMode) ?? "") ?? .fileURL
    }

    /// Capture, then put the result on the clipboard.
    ///
    /// How:
    /// 1. Snapshot settings on the main actor so the background task stays `Sendable`.
    /// 2. Run `screencapture` off the main actor — it owns the UI until the user finishes.
    /// 3. Reap old temp files *after* the capture, never before it.
    /// 4. Hop back to the main actor to touch the pasteboard.
    func capture(mode: CaptureMode) {
        let store = TempStore(retention: defaults.double(forKey: DefaultsKey.retentionHours) * 3600)
        let destination = store.newFileURL()
        let clipboard = clipboardMode
        let silent = defaults.bool(forKey: DefaultsKey.silentShutter)

        Task.detached(priority: .userInitiated) {
            do {
                let result = try Capturer().capture(mode: mode, to: destination, silent: silent)
                store.cleanup()

                guard case .captured(let url) = result else { return }
                await MainActor.run {
                    Pasteboard.write(url, as: clipboard)
                }
            } catch {
                PBLog.agent.error("Capture failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
