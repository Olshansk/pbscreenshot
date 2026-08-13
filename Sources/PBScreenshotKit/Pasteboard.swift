import AppKit
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

public enum Pasteboard {
    /// Place a captured file on a pasteboard in the requested form.
    ///
    /// - Parameter pasteboard: Defaults to the system clipboard. Tests pass a private
    ///   pasteboard so running the suite never clobbers what the user has copied.
    /// - Returns: `false` if the mode needed the file's contents and they could not be read.
    @discardableResult
    public static func write(
        _ fileURL: URL,
        as mode: ClipboardMode,
        to pasteboard: NSPasteboard = .general
    ) -> Bool {
        switch mode {
        case .none:
            return true

        case .fileURL:
            pasteboard.clearContents()
            pasteboard.writeObjects([fileURL as NSURL])
            PBLog.pasteboard.debug("Wrote file reference to clipboard")
            return true

        case .path:
            pasteboard.clearContents()
            pasteboard.setString(fileURL.path, forType: .string)
            return true

        case .image:
            guard let image = NSImage(contentsOf: fileURL) else {
                PBLog.pasteboard.error("Could not read image at \(fileURL.path, privacy: .public)")
                return false
            }
            pasteboard.clearContents()
            pasteboard.writeObjects([image])
            return true
        }
    }
}
