import KeyboardShortcuts
import PBScreenshotKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @AppStorage(DefaultsKey.clipboardMode) private var clipboardMode = ClipboardMode.fileURL.rawValue
    @AppStorage(DefaultsKey.retentionHours) private var retentionHours = 1.0
    @AppStorage(DefaultsKey.silentShutter) private var silentShutter = false
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section("Hotkeys") {
                KeyboardShortcuts.Recorder("Capture region:", name: .captureRegion)
                KeyboardShortcuts.Recorder("Capture full screen:", name: .captureFullScreen)
            }

            Section("Clipboard") {
                Picker("Copy as:", selection: $clipboardMode) {
                    Text("File reference").tag(ClipboardMode.fileURL.rawValue)
                    Text("File path (text)").tag(ClipboardMode.path.rawValue)
                    Text("Image data").tag(ClipboardMode.image.rawValue)
                    Text("Nothing").tag(ClipboardMode.none.rawValue)
                }
                Text("A file reference pastes like Finder — chat apps and CLI tools attach the image instead of raw pixels.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Behavior") {
                Toggle("Silent shutter", isOn: $silentShutter)
                Toggle(
                    "Launch at login",
                    isOn: Binding(
                        get: { launchAtLogin },
                        set: { enabled in
                            launchAtLogin = enabled
                            setLaunchAtLogin(enabled)
                        }
                    )
                )
                Stepper(
                    "Delete temp captures after \(Int(retentionHours))h",
                    value: $retentionHours,
                    in: 1...72,
                    step: 1
                )
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            PBLog.agent.error(
                "Launch at login \(enabled ? "register" : "unregister", privacy: .public) failed: \(error.localizedDescription, privacy: .public)"
            )
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
