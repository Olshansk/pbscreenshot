import Foundation

/// What to capture.
public enum CaptureMode: String, Sendable, CaseIterable {
    /// Drag to select a region (the crosshair). Cancellable with Esc.
    case interactive
    /// The entire screen, no interaction.
    case full
    /// Click to pick a window.
    case window

    /// Whether the user can abort this mode without producing a file.
    public var isCancellable: Bool {
        self != .full
    }
}

public enum CaptureResult: Sendable, Equatable {
    case captured(URL)
    /// User pressed Esc. `screencapture` still exits 0, so this is detected by
    /// the absence of the output file.
    case cancelled
}
