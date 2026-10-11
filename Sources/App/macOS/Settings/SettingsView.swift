import AppKit
import KeyboardShortcuts
import PBScreenshotKit
import PBScreenshotMacOS
import SwiftUI

struct SettingsView: View {
    @AppStorage(DefaultsKey.isEnabled) private var isEnabled = true
    @AppStorage(DefaultsKey.clipboardMode) private var clipboardMode = ClipboardMode.fileURL.rawValue
    @AppStorage(DefaultsKey.retentionHours) private var retentionHours = 1.0
    @AppStorage(DefaultsKey.silentShutter) private var silentShutter = false
    @StateObject private var loginItem = LoginItem()
    @StateObject private var permission = ScreenRecordingPermission()
    @ObservedObject private var capture = CaptureService.shared

    var body: some View {
        Form {
            Section {
                Toggle("Enable pbscreenshot", isOn: $isEnabled)
                    .help("Pause captures and release the global hotkeys without quitting.")
                Toggle("Launch at login", isOn: Binding(
                    get: { loginItem.isRegistered },
                    set: { loginItem.setEnabled($0) }
                ))
                if loginItem.status == .requiresApproval {
                    Text("Launch at login needs approval in System Settings.")
                    Button("Open Login Items Settings") { loginItem.openSettings() }
                } else if loginItem.status == .notFound {
                    Text("macOS has not registered this app for launch at login.")
                }
                if let error = loginItem.errorMessage {
                    Text("Could not change launch at login: \(error)")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Hotkeys") {
                KeyboardShortcuts.Recorder("Capture region:", name: .captureRegion)
                KeyboardShortcuts.Recorder("Capture full screen:", name: .captureFullScreen)
                Text("Click a shortcut and press your preferred key combination.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Screen Recording") {
                Label(
                    permission.isGranted ? "Allowed for this running app" : "Permission needed",
                    systemImage: permission.isGranted ? "checkmark.circle" : "exclamationmark.circle"
                )
                if !permission.isGranted {
                    Button("Allow Screen Recording") { permission.request() }
                }
                Button("Open Screen Recording Settings") { permission.openSettings() }
                Button("Check Again") { permission.refresh() }
                Text("If access is enabled in System Settings but capture still fails, quit pbscreenshot and reopen it from Applications. Hotkeys do not require Accessibility access.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let error = capture.errorMessage {
                Section("Last capture") {
                    Text(error)
                    Button("Dismiss") { capture.errorMessage = nil }
                }
            }

            DisclosureGroup("Advanced") {
                Picker("Copy as:", selection: $clipboardMode) {
                    Text("File reference").tag(ClipboardMode.fileURL.rawValue)
                    Text("File path (text)").tag(ClipboardMode.path.rawValue)
                    Text("Image data").tag(ClipboardMode.image.rawValue)
                    Text("Nothing").tag(ClipboardMode.none.rawValue)
                }
                Toggle("Silent shutter", isOn: $silentShutter)
                Stepper("Delete temp captures after \(Int(retentionHours))h", value: $retentionHours, in: 1...72, step: 1)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 440, minHeight: 540)
        .onAppear { refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refresh()
        }
        .onChange(of: isEnabled) { enabled in Hotkeys.setEnabled(enabled) }
    }

    private func refresh() {
        permission.refresh()
        loginItem.refresh()
    }
}
