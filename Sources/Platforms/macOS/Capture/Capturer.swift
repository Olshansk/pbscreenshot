import Foundation
import PBScreenshotKit

extension CaptureMode {
    var screencaptureArguments: [String] {
        switch self {
        case .interactive: ["-i"]
        case .full: []
        case .window: ["-w"]
        }
    }
}

public enum CaptureError: Error, LocalizedError, Equatable {
    case launchFailed(String)
    case exited(code: Int32)

    public var errorDescription: String? {
        switch self {
        case .launchFailed(let reason):
            "Could not run /usr/sbin/screencapture: \(reason)"
        case .exited(let code):
            "screencapture exited with status \(code)"
        }
    }
}

/// Wraps `/usr/sbin/screencapture`.
///
/// Shelling out rather than using ScreenCaptureKit is deliberate: the system
/// binary gives the native selection UI, the shutter sound, and Retina-correct
/// output for free, and it is the same code path the OS uses for Cmd+Shift+4.
public struct Capturer: Sendable {
    public static let defaultExecutablePath = "/usr/sbin/screencapture"

    /// Overridable so tests can substitute a stand-in binary and exercise the
    /// exit-code and cancellation paths without needing Screen Recording.
    public let executablePath: String

    public init(executablePath: String = Capturer.defaultExecutablePath) {
        self.executablePath = executablePath
    }

    /// Capture to `url` and report whether a file actually landed.
    ///
    /// How:
    /// 1. Build arguments for the mode, optionally silencing the shutter.
    /// 2. Run `screencapture` and wait — the process owns the UI until the user finishes.
    /// 3. Treat a non-zero exit as an error.
    /// 4. Treat a zero exit with no file as a user cancellation, which is normal.
    public func capture(
        mode: CaptureMode,
        to url: URL,
        silent: Bool = false
    ) throws -> CaptureResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments =
            (silent ? ["-x"] : []) + mode.screencaptureArguments + [url.path]

        do {
            try process.run()
        } catch {
            throw CaptureError.launchFailed(error.localizedDescription)
        }
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw CaptureError.exited(code: process.terminationStatus)
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            PBLog.capture.debug("Capture cancelled by user")
            return .cancelled
        }

        PBLog.capture.debug("Captured to \(url.path, privacy: .public)")
        return .captured(url)
    }
}
