import AppKit
import PBScreenshotKit
import SwiftUI

@main
struct PBScreenshotAgentApp: App {
    @NSApplicationDelegateAdaptor(AgentDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra("pbscreenshot", systemImage: "camera.viewfinder") {
            Button("Capture Region") {
                CaptureService.shared.capture(mode: .interactive)
            }
            Button("Capture Full Screen") {
                CaptureService.shared.capture(mode: .full)
            }
            Button("Capture Window") {
                CaptureService.shared.capture(mode: .window)
            }

            Divider()

            if #available(macOS 14.0, *) {
                SettingsLink { Text("Settings…") }
            } else {
                Button("Settings…") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
            }

            Button("Quit pbscreenshot") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }

        Settings {
            SettingsView()
        }
    }
}

@MainActor
final class AgentDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !terminateIfAlreadyRunning() else { return }
        Hotkeys.register()
    }

    /// Hand off to an already-running copy and terminate this one.
    ///
    /// Users routinely end up with two copies — one from the DMG in /Applications
    /// and one from a `brew install --cask` — and duplicate menu bar icons plus
    /// contended hotkey registration is a confusing failure. First one wins.
    private func terminateIfAlreadyRunning() -> Bool {
        let current = NSRunningApplication.current
        let existing = NSWorkspace.shared.runningApplications.first {
            $0.bundleIdentifier == current.bundleIdentifier
                && $0.processIdentifier != current.processIdentifier
        }
        guard let existing else { return false }

        PBLog.agent.notice(
            "Another instance is running (pid \(existing.processIdentifier, privacy: .public)) — terminating this one"
        )
        existing.activate()
        NSApp.terminate(nil)
        return true
    }
}
