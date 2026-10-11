import AppKit
import PBScreenshotKit
import PBScreenshotMacOS
import SwiftUI

@main
struct PBScreenshotAgentApp: App {
    @NSApplicationDelegateAdaptor(AgentDelegate.self) private var delegate
    @AppStorage(DefaultsKey.isEnabled) private var isEnabled = true
    @ObservedObject private var capture = CaptureService.shared

    var body: some Scene {
        MenuBarExtra(isEnabled ? "pbscreenshot" : "pbscreenshot — Paused", systemImage: isEnabled ? "camera.viewfinder" : "pause.circle") {
            Toggle("Enable pbscreenshot", isOn: $isEnabled)
                .onChange(of: isEnabled) { enabled in Hotkeys.setEnabled(enabled) }
            Divider()
            Group {
                Button("Capture Region") { capture.capture(mode: .interactive) }
                Button("Capture Full Screen") { capture.capture(mode: .full) }
                Button("Capture Window") { capture.capture(mode: .window) }
            }
            .disabled(!isEnabled || capture.isCapturing)
            Divider()
            Button("Settings…") { SettingsWindow.shared.show() }
                .keyboardShortcut(",")
            Button("Quit pbscreenshot") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}

@MainActor
final class AgentDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !terminateIfAlreadyRunning() else { return }
        Hotkeys.register()
        if !ScreenRecordingPermission().isGranted {
            SettingsWindow.shared.show()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        SettingsWindow.shared.show()
        return true
    }

    /// Hand off to an already-running copy and terminate this one.
    private func terminateIfAlreadyRunning() -> Bool {
        let current = NSRunningApplication.current
        guard let identifier = current.bundleIdentifier else { return false }
        let existing = NSWorkspace.shared.runningApplications.first {
            $0.bundleIdentifier == identifier && $0.processIdentifier != current.processIdentifier
        }
        guard let existing else { return false }
        NSWorkspace.shared.openApplication(at: existing.bundleURL ?? Bundle.main.bundleURL, configuration: .init())
        NSApp.terminate(nil)
        return true
    }
}
