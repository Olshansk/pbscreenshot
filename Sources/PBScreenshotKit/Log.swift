import os

/// Unified logging for the kit.
///
/// Deliberately `os.Logger` rather than a file-backed singleton: two processes
/// (CLI and agent) can run at once, and a shared log file invites write races.
public enum PBLog {
    public static let subsystem = "com.olshansky.pbscreenshot"

    public static let capture = Logger(subsystem: subsystem, category: "capture")
    public static let pasteboard = Logger(subsystem: subsystem, category: "pasteboard")
    public static let store = Logger(subsystem: subsystem, category: "store")
    public static let agent = Logger(subsystem: subsystem, category: "agent")
}
