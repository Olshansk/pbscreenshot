import AppKit
import PBScreenshotKit

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
            let written = pasteboard.writeObjects([fileURL as NSURL])
            PBLog.pasteboard.debug("Wrote file reference to clipboard")
            return written

        case .path:
            pasteboard.clearContents()
            return pasteboard.setString(fileURL.path, forType: .string)

        case .image:
            guard let image = NSImage(contentsOf: fileURL) else {
                PBLog.pasteboard.error("Could not read image at \(fileURL.path, privacy: .public)")
                return false
            }
            pasteboard.clearContents()
            return pasteboard.writeObjects([image])
        }
    }
}
