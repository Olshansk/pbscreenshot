import AppKit
import PBScreenshotKit
import PBScreenshotMacOS
import SwiftUI

/// Runs one capture at a time on behalf of the menu and hotkeys.
@MainActor
final class CaptureService: ObservableObject {
    static let shared = CaptureService()
    @Published private(set) var isCapturing = false
    @Published var errorMessage: String?
    private let defaults = UserDefaults.standard

    private init() {
        defaults.register(defaults: [
            DefaultsKey.isEnabled: true,
            DefaultsKey.clipboardMode: ClipboardMode.fileURL.rawValue,
            DefaultsKey.retentionHours: 1.0,
            DefaultsKey.silentShutter: false,
        ])
    }

    /// Capture, then put the result on the clipboard.
    ///
    /// How:
    /// 1. Reject disabled, concurrent, or unauthorized captures.
    /// 2. Snapshot preferences before starting the background capture.
    /// 3. Reap old temporary files after capture completes.
    /// 4. Publish errors or write the clipboard on the main actor.
    func capture(mode: CaptureMode) {
        guard defaults.bool(forKey: DefaultsKey.isEnabled), !isCapturing else { return }
        guard ScreenRecordingPermission().isGranted else {
            errorMessage = "Allow Screen Recording, then try again. If already allowed, quit and reopen pbscreenshot."
            SettingsWindow.shared.show()
            return
        }
        isCapturing = true
        errorMessage = nil
        let store = TempStore(retention: max(1, defaults.double(forKey: DefaultsKey.retentionHours)) * 3600)
        let destination = store.newFileURL()
        let clipboard = ClipboardMode(rawValue: defaults.string(forKey: DefaultsKey.clipboardMode) ?? "") ?? .fileURL
        let silent = defaults.bool(forKey: DefaultsKey.silentShutter)

        Task {
            defer { isCapturing = false }
            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    let result = try Capturer().capture(mode: mode, to: destination, silent: silent)
                    store.cleanup()
                    return result
                }.value
                guard case .captured(let url) = result else { return }
                guard Pasteboard.write(url, as: clipboard) else {
                    throw CocoaError(.fileReadUnknown)
                }
            } catch {
                errorMessage = "Capture failed: \(error.localizedDescription)"
                PBLog.agent.error("Capture failed: \(error.localizedDescription, privacy: .public)")
                SettingsWindow.shared.show()
            }
        }
    }
}
