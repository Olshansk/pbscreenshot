import AppKit
import Foundation
import Testing

@testable import PBScreenshotKit

// MARK: - TempStore

@Suite("TempStore")
struct TempStoreTests {
    /// A scratch directory that cleans itself up.
    private func makeScratch() throws -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("pbscreenshot-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func touch(_ url: URL, age: TimeInterval) throws {
        try Data("x".utf8).write(to: url)
        let stamp = Date().addingTimeInterval(-age)
        try FileManager.default.setAttributes(
            [.creationDate: stamp, .modificationDate: stamp],
            ofItemAtPath: url.path
        )
    }

    @Test("Generated filenames carry the managed prefix and a millisecond stamp")
    func newFileURLNaming() {
        let store = TempStore(directory: URL(fileURLWithPath: "/tmp"))
        let name = store.newFileURL(now: Date(timeIntervalSince1970: 1_700_000_000))
            .lastPathComponent

        #expect(name == "pbscreenshot-1700000000000.png")
        #expect(TempStore.isManaged(name))
    }

    @Test("Only our own files are considered managed")
    func managedDetection() {
        #expect(TempStore.isManaged("pbscreenshot-123.png"))
        #expect(!TempStore.isManaged("screenshot-123.png"))
        #expect(!TempStore.isManaged("pbscreenshot-123.txt"))
        #expect(!TempStore.isManaged("claude-companion-screenshot-123.png"))
    }

    @Test("Cleanup reaps expired captures, spares fresh ones, and never touches foreign files")
    func cleanupSelectivity() throws {
        let scratch = try makeScratch()
        defer { try? FileManager.default.removeItem(at: scratch) }

        let expired = scratch.appendingPathComponent("pbscreenshot-1.png")
        let fresh = scratch.appendingPathComponent("pbscreenshot-2.png")
        let foreign = scratch.appendingPathComponent("someone-elses-file.png")

        try touch(expired, age: 7200)
        try touch(fresh, age: 60)
        try touch(foreign, age: 7200)

        let store = TempStore(directory: scratch, retention: 3600)
        let removed = store.cleanup()

        #expect(removed == 1)
        #expect(!FileManager.default.fileExists(atPath: expired.path))
        #expect(FileManager.default.fileExists(atPath: fresh.path))
        #expect(FileManager.default.fileExists(atPath: foreign.path))
    }

    @Test("Cleanup on a missing directory is a no-op rather than an error")
    func cleanupMissingDirectory() {
        let store = TempStore(directory: URL(fileURLWithPath: "/nonexistent-\(UUID().uuidString)"))
        #expect(store.cleanup() == 0)
    }
}

// MARK: - Capture

@Suite("Capture")
struct CaptureTests {
    @Test("Modes map to the expected screencapture flags")
    func modeArguments() {
        #expect(CaptureMode.interactive.screencaptureArguments == ["-i"])
        #expect(CaptureMode.full.screencaptureArguments == [])
        #expect(CaptureMode.window.screencaptureArguments == ["-w"])
    }

    @Test("Only interactive modes can be cancelled")
    func cancellability() {
        #expect(CaptureMode.interactive.isCancellable)
        #expect(CaptureMode.window.isCancellable)
        #expect(!CaptureMode.full.isCancellable)
    }

    @Test("screencapture is where macOS keeps it")
    func executableExists() {
        #expect(FileManager.default.isExecutableFile(atPath: Capturer.defaultExecutablePath))
    }

    private func scratchURL() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("pbscreenshot-capture-\(UUID().uuidString).png")
    }

    @Test("A zero exit that writes no file reads as a cancellation, not a success")
    func cancellationDetection() throws {
        // Esc during region select: screencapture exits 0 and writes nothing.
        let url = scratchURL()
        let result = try Capturer(executablePath: "/usr/bin/true").capture(mode: .full, to: url)

        #expect(result == .cancelled)
    }

    @Test("A written file reads as a successful capture")
    func captureSuccess() throws {
        // touch receives the destination path as its only argument, like screencapture.
        let url = scratchURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try Capturer(executablePath: "/usr/bin/touch").capture(mode: .full, to: url)

        #expect(result == .captured(url))
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    @Test("A non-zero exit surfaces as an error rather than a silent no-op")
    func failurePropagates() {
        let url = scratchURL()
        #expect(throws: CaptureError.exited(code: 1)) {
            try Capturer(executablePath: "/usr/bin/false").capture(mode: .full, to: url)
        }
    }
}

// MARK: - Pasteboard

@Suite("Pasteboard")
struct PasteboardTests {
    /// A private pasteboard, so the suite never disturbs the user's clipboard.
    private func makePasteboard() -> NSPasteboard {
        NSPasteboard(name: .init("com.olshansky.pbscreenshot.tests.\(UUID().uuidString)"))
    }

    private func makePNG() throws -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("pbscreenshot-test-\(UUID().uuidString).png")
        let image = NSImage(size: NSSize(width: 2, height: 2))
        image.lockFocus()
        NSColor.systemPink.drawSwatch(in: NSRect(x: 0, y: 0, width: 2, height: 2))
        image.unlockFocus()

        guard let tiff = image.tiffRepresentation,
            let rep = NSBitmapImageRep(data: tiff),
            let png = rep.representation(using: .png, properties: [:])
        else {
            throw CocoaError(.fileWriteUnknown)
        }
        try png.write(to: url)
        return url
    }

    @Test("File-reference mode writes a real file URL, the way Finder does")
    func fileURLMode() throws {
        let file = try makePNG()
        defer { try? FileManager.default.removeItem(at: file) }
        let pasteboard = makePasteboard()

        #expect(Pasteboard.write(file, as: .fileURL, to: pasteboard))

        let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL]
        #expect(urls?.count == 1)
        #expect(urls?.first?.path == file.path)
    }

    @Test("Path mode writes plain text, not a file reference")
    func pathMode() throws {
        let file = try makePNG()
        defer { try? FileManager.default.removeItem(at: file) }
        let pasteboard = makePasteboard()

        #expect(Pasteboard.write(file, as: .path, to: pasteboard))
        #expect(pasteboard.string(forType: .string) == file.path)
    }

    @Test("Image mode puts decodable image data on the pasteboard")
    func imageMode() throws {
        let file = try makePNG()
        defer { try? FileManager.default.removeItem(at: file) }
        let pasteboard = makePasteboard()

        #expect(Pasteboard.write(file, as: .image, to: pasteboard))
        #expect(pasteboard.readObjects(forClasses: [NSImage.self])?.isEmpty == false)
    }

    @Test("Image mode reports failure when the file is not an image")
    func imageModeRejectsGarbage() throws {
        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("pbscreenshot-garbage-\(UUID().uuidString).png")
        try Data("not an image".utf8).write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }

        #expect(!Pasteboard.write(file, as: .image, to: makePasteboard()))
    }

    @Test("None mode leaves the pasteboard untouched")
    func noneMode() throws {
        let file = try makePNG()
        defer { try? FileManager.default.removeItem(at: file) }
        let pasteboard = makePasteboard()
        pasteboard.clearContents()
        pasteboard.setString("preexisting", forType: .string)

        #expect(Pasteboard.write(file, as: .none, to: pasteboard))
        #expect(pasteboard.string(forType: .string) == "preexisting")
    }

    @Test("Clipboard modes round-trip through their CLI spellings")
    func modeSpellings() {
        #expect(ClipboardMode(rawValue: "file-url") == .fileURL)
        #expect(ClipboardMode.allCases.map(\.rawValue).sorted() == ["file-url", "image", "none", "path"])
    }
}
