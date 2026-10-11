import ArgumentParser
import Foundation
import PBScreenshotKit
import PBScreenshotMacOS

extension CaptureMode: ExpressibleByArgument {}
extension ClipboardMode: ExpressibleByArgument {}

@main
struct PBScreenshotCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pbscreenshot",
        abstract: "Capture a screenshot and put it on the clipboard as a file reference.",
        discussion: """
            Unlike `screencapture -c`, which puts raw image bytes on the clipboard, \
            this copies the file itself the way Finder does. CLI tools and chat apps \
            then attach the image instead of pasting pixels.

            Exit codes: 0 captured, 1 error, 2 cancelled by user.
            """,
        version: PBScreenshot.version
    )

    @Option(name: [.short, .long], help: "What to capture: interactive, full, or window.")
    var mode: CaptureMode = .interactive

    @Option(name: [.short, .long], help: "Where to write the PNG. Defaults to a temp file.")
    var output: String?

    @Option(name: .long, help: "Clipboard form: file-url, path, image, or none.")
    var copy: ClipboardMode = .fileURL

    @Flag(name: .long, help: "Skip cleanup of old temp captures.")
    var keep = false

    @Flag(name: .long, help: "Emit a JSON result object.")
    var json = false

    @Flag(name: .long, help: "Suppress the shutter sound.")
    var silent = false

    @Flag(name: [.short, .long], help: "Print nothing on success.")
    var quiet = false

    func run() throws {
        let store = TempStore()
        let destination = output.map { URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath) }
            ?? store.newFileURL()

        let result: CaptureResult
        do {
            result = try Capturer().capture(mode: mode, to: destination, silent: silent)
        } catch {
            if json { emit(path: nil, cancelled: false, error: error.localizedDescription) }
            throw ExitCode.failure
        }

        if !keep {
            store.cleanup()
        }

        switch result {
        case .cancelled:
            if json { emit(path: nil, cancelled: true, error: nil) }
            throw ExitCode(2)

        case .captured(let url):
            Pasteboard.write(url, as: copy)
            if json {
                emit(path: url.path, cancelled: false, error: nil)
            } else if !quiet {
                print(url.path)
            }
        }
    }

    /// Emit a single-line JSON object so callers can parse without a JSON tool.
    private func emit(path: String?, cancelled: Bool, error: String?) {
        var object: [String: Any] = [
            "cancelled": cancelled,
            "clipboard": copy.rawValue,
            "mode": mode.rawValue,
        ]
        object["path"] = path
        object["error"] = error

        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]),
            let line = String(data: data, encoding: .utf8)
        else { return }
        print(line)
    }
}
