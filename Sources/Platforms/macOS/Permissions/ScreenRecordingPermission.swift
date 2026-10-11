import AppKit
import Combine
import CoreGraphics

/// Screen Recording belongs to the running app's identity, not a saved preference.
@MainActor
public final class ScreenRecordingPermission: ObservableObject {
    @Published public private(set) var isGranted: Bool
    private let preflight: () -> Bool
    private let requestAccess: () -> Bool

    public init(
        preflight: @escaping () -> Bool = { CGPreflightScreenCaptureAccess() },
        requestAccess: @escaping () -> Bool = { CGRequestScreenCaptureAccess() }
    ) {
        self.preflight = preflight
        self.requestAccess = requestAccess
        isGranted = preflight()
    }

    public func refresh() {
        isGranted = preflight()
    }

    /// Request only after a user action; an existing denial needs System Settings.
    public func request() {
        _ = requestAccess()
        refresh()
    }

    public func openSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") else { return }
        NSWorkspace.shared.open(url)
    }
}
