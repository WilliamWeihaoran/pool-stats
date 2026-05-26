import XCTest
@testable import PoolStats

final class LocalSessionPersistenceTests: XCTestCase {
    func testLocalSessionCacheRemovesCorruptFileOnLoad() throws {
        let tempDir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let url = tempDir.appendingPathComponent("sessions.json")
        try Data("not-json".utf8).write(to: url)

        let cache = LocalSessionCache(url: url)
        let loaded = cache.loadSessions()

        XCTAssertTrue(loaded.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func testLocalSessionCacheRemovesEmptyFileOnLoad() throws {
        let tempDir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let url = tempDir.appendingPathComponent("sessions.json")
        try Data().write(to: url)

        let cache = LocalSessionCache(url: url)
        let loaded = cache.loadSessions()

        XCTAssertTrue(loaded.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func testDeletedSessionIDStoreRemovesCorruptFileOnLoad() throws {
        let tempDir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let url = tempDir.appendingPathComponent("deleted-session-ids.json")
        try Data("{".utf8).write(to: url)

        let store = DeletedSessionIDStore(url: url)
        let ids = store.load()

        XCTAssertTrue(ids.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func testDeletedSessionIDStoreRemovesEmptyFileOnLoad() throws {
        let tempDir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let url = tempDir.appendingPathComponent("deleted-session-ids.json")
        try Data().write(to: url)

        let store = DeletedSessionIDStore(url: url)
        let ids = store.load()

        XCTAssertTrue(ids.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    private func makeTempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
