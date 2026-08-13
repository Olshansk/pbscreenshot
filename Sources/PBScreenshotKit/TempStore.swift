import Foundation

/// Allocates temp paths for captures and reaps old ones.
///
/// Cleanup is intentionally *not* run before a capture — a temp-directory scan
/// has variable cost (it grows with unrelated junk from every app on the system)
/// and must never sit in front of the capture UI.
public struct TempStore: Sendable {
    public static let filePrefix = "pbscreenshot-"
    public static let fileExtension = "png"

    public let directory: URL
    public let retention: TimeInterval

    /// - Parameters:
    ///   - directory: Where captures land. Defaults to the user temp directory.
    ///   - retention: Age past which a capture is reaped. Defaults to 1 hour.
    public init(
        directory: URL = URL(fileURLWithPath: NSTemporaryDirectory()),
        retention: TimeInterval = 3600
    ) {
        self.directory = directory
        self.retention = retention
    }

    /// A fresh, collision-free path: `pbscreenshot-<epoch-millis>.png`.
    public func newFileURL(now: Date = Date()) -> URL {
        let millis = Int(now.timeIntervalSince1970 * 1000)
        return directory.appendingPathComponent(
            "\(Self.filePrefix)\(millis).\(Self.fileExtension)"
        )
    }

    /// Whether a filename is one of ours. Guards against reaping unrelated files.
    public static func isManaged(_ filename: String) -> Bool {
        filename.hasPrefix(filePrefix) && filename.hasSuffix(".\(fileExtension)")
    }

    /// Delete managed captures older than `retention`.
    ///
    /// How:
    /// 1. List the directory, tolerating failure (nothing to clean is not an error).
    /// 2. Keep only files matching our prefix/extension so we never touch other apps' files.
    /// 3. Read each file's creation date, falling back to modification date.
    /// 4. Remove those older than the cutoff, ignoring individual failures.
    ///
    /// - Returns: How many files were removed.
    @discardableResult
    public func cleanup(now: Date = Date()) -> Int {
        let fm = FileManager.default
        guard let names = try? fm.contentsOfDirectory(atPath: directory.path) else { return 0 }

        let cutoff = now.addingTimeInterval(-retention)
        var removed = 0

        for name in names where Self.isManaged(name) {
            let fileURL = directory.appendingPathComponent(name)
            guard let attrs = try? fm.attributesOfItem(atPath: fileURL.path) else { continue }
            let stamp = (attrs[.creationDate] as? Date) ?? (attrs[.modificationDate] as? Date)
            guard let stamp, stamp < cutoff else { continue }

            if (try? fm.removeItem(at: fileURL)) != nil {
                removed += 1
            }
        }

        if removed > 0 {
            PBLog.store.debug("Reaped \(removed, privacy: .public) old capture(s)")
        }
        return removed
    }
}
