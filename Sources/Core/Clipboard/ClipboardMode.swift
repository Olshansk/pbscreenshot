import Foundation

/// What form the capture takes on the clipboard.
public enum ClipboardMode: String, Sendable, CaseIterable {
    /// A file *reference*, exactly like copying in Finder. This is the mode that
    /// makes CLI tools and chat apps attach the image instead of pasting bytes,
    /// and it is the reason this tool exists — `pbcopy` cannot produce it.
    case fileURL = "file-url"
    /// The POSIX path as plain text.
    case path
    /// Raw image data, matching `screencapture -c`.
    case image
    /// Leave the clipboard untouched.
    case none
}
