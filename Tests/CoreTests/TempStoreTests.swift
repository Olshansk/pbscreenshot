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
