import XCTest
@testable import PoolStats

@MainActor
final class DataStoreDeletionTests: XCTestCase {
    private let pendingAccountDeletionCleanupKey = "pendingAccountDeletionCloudCleanup"

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: pendingAccountDeletionCleanupKey)
        super.tearDown()
    }

    func testDeleteAccountTreatsCloudErrorAsSuccessWhenRemoteDataIsGone() async throws {
        let service = FakeSessionService()
        service.deleteAllUserDataError = FakeError.sample
        service.hasAnyUserDataResult = false
        let (store, localCache, tempDir) = makeStore(service: service)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let session = makeSession(id: 1, ts: Date(timeIntervalSince1970: 1_000), racks: [makeRack(index: 1)])
        localCache.saveSessions([session])
        store.sessions = [session]

        try await store.deleteAllUserDataForAccountDeletion()

        XCTAssertTrue(store.sessions.isEmpty)
        XCTAssertNil(store.lastError)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: pendingAccountDeletionCleanupKey))
        XCTAssertTrue(store.lastSyncFailureReason == nil)
        if case .synced = store.syncStatus {
        } else {
            XCTFail("Expected synced status after verified remote cleanup.")
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: localCache.url.path))
    }

    func testDeleteAccountKeepsFailureWhenRemoteDataStillExists() async {
        let service = FakeSessionService()
        service.deleteAllUserDataError = FakeError.sample
        service.hasAnyUserDataResult = true
        let (store, localCache, tempDir) = makeStore(service: service)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let session = makeSession(id: 2, ts: Date(timeIntervalSince1970: 2_000), racks: [makeRack(index: 1)])
        localCache.saveSessions([session])
        store.sessions = [session]

        do {
            try await store.deleteAllUserDataForAccountDeletion()
            XCTFail("Expected delete to throw when CloudKit still reports remaining data.")
        } catch {
        }

        XCTAssertTrue(store.sessions.isEmpty)
        XCTAssertEqual(store.lastError, "Deleted local session history. iCloud cleanup failed.")
        XCTAssertTrue(UserDefaults.standard.bool(forKey: pendingAccountDeletionCleanupKey))
        if case .localOnly(let message) = store.syncStatus {
            XCTAssertEqual(message, "Deleted local session history. iCloud cleanup failed.")
        } else {
            XCTFail("Expected localOnly status after real iCloud delete failure.")
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: localCache.url.path))
    }

    func testDeleteAccountKeepsPendingCleanupWhenCloudVerificationIsInconclusive() async {
        let service = FakeSessionService()
        service.hasAnyUserDataError = FakeError.sample
        let (store, localCache, tempDir) = makeStore(service: service)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let session = makeSession(id: 3, ts: Date(timeIntervalSince1970: 3_000), racks: [makeRack(index: 1)])
        localCache.saveSessions([session])
        store.sessions = [session]

        do {
            try await store.deleteAllUserDataForAccountDeletion()
            XCTFail("Expected delete to remain pending when iCloud verification is unavailable.")
        } catch {
        }

        XCTAssertTrue(store.sessions.isEmpty)
        XCTAssertEqual(store.lastError, "Account deletion will finish when iCloud is available.")
        XCTAssertTrue(UserDefaults.standard.bool(forKey: pendingAccountDeletionCleanupKey))
        let deletedStore = DeletedSessionIDStore(url: tempDir.appendingPathComponent("deleted-session-ids.json"))
        XCTAssertEqual(deletedStore.load(), Set([session.id]))
        if case .localOnly(let message) = store.syncStatus {
            XCTAssertEqual(message, "Account deletion will finish when iCloud is available.")
        } else {
            XCTFail("Expected localOnly status while iCloud cleanup is pending.")
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: localCache.url.path))
    }

    func testDeleteAccountVerifiesRemoteDataIsGoneEvenWhenDeleteCallSucceeds() async {
        let service = FakeSessionService()
        service.hasAnyUserDataResult = true
        let (store, _, tempDir) = makeStore(service: service)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        store.sessions = [makeSession(id: 4, ts: Date(timeIntervalSince1970: 4_000), racks: [makeRack(index: 1)])]

        do {
            try await store.deleteAllUserDataForAccountDeletion()
            XCTFail("Expected delete to remain pending while CloudKit still has user data.")
        } catch {
        }

        XCTAssertTrue(store.sessions.isEmpty)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: pendingAccountDeletionCleanupKey))
        XCTAssertEqual(store.lastError, "Deleted local session history. iCloud cleanup failed.")
    }

    func testPendingAccountDeletionRefreshDoesNotRehydrateCloudSessionsWhenCleanupStillPending() async {
        UserDefaults.standard.set(true, forKey: pendingAccountDeletionCleanupKey)
        let service = FakeSessionService()
        service.deleteAllUserDataError = FakeError.sample
        service.hasAnyUserDataResult = true
        service.fetchedSessions = [makeSession(id: 5, ts: Date(timeIntervalSince1970: 5_000), racks: [makeRack(index: 1)])]
        let (store, localCache, tempDir) = makeStore(service: service)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        await store.refresh()

        XCTAssertTrue(store.sessions.isEmpty)
        XCTAssertEqual(service.fetchAllSessionsCallCount, 0)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: pendingAccountDeletionCleanupKey))
        XCTAssertFalse(FileManager.default.fileExists(atPath: localCache.url.path))
        if case .localOnly(let message) = store.syncStatus {
            XCTAssertEqual(message, "Account deletion will finish when iCloud is available.")
        } else {
            XCTFail("Expected localOnly status while pending cleanup blocks refresh.")
        }
    }

    func testPendingAccountDeletionRefreshStopsAfterVerifiedCleanup() async {
        UserDefaults.standard.set(true, forKey: pendingAccountDeletionCleanupKey)
        let service = FakeSessionService()
        service.hasAnyUserDataResult = false
        service.fetchedSessions = [makeSession(id: 6, ts: Date(timeIntervalSince1970: 6_000), racks: [makeRack(index: 1)])]
        let (store, _, tempDir) = makeStore(service: service)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        await store.refresh()

        XCTAssertTrue(store.sessions.isEmpty)
        XCTAssertEqual(service.fetchAllSessionsCallCount, 0)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: pendingAccountDeletionCleanupKey))
        if case .synced = store.syncStatus {
        } else {
            XCTFail("Expected synced status after verified pending cleanup.")
        }
    }

    private func makeStore(service: FakeSessionService) -> (DataStore, LocalSessionCache, URL) {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let localCache = LocalSessionCache(url: tempDir.appendingPathComponent("sessions.json"))
        let deletedStore = DeletedSessionIDStore(url: tempDir.appendingPathComponent("deleted-session-ids.json"))
        let store = DataStore(
            service: service,
            localCache: localCache,
            deletedSessionIDStore: deletedStore,
            autoRefresh: false
        )
        return (store, localCache, tempDir)
    }
}

private enum FakeError: Error {
    case sample
}

private final class FakeSessionService: SessionServicing {
    var deleteAllUserDataError: Error?
    var hasAnyUserDataError: Error?
    var hasAnyUserDataResult = false
    var fetchedSessions: [Session] = []
    var fetchAllSessionsCallCount = 0

    func fetchAllSessions() async throws -> [Session] {
        fetchAllSessionsCallCount += 1
        return fetchedSessions
    }
    func saveSession(_ session: Session) async throws {}
    func updateSessionMeta(_ session: Session) async throws {}
    func deleteSessions(_ ids: [Int64]) async throws {}
    func replaceAllSessions(existingIDs: [Int64], with newSessions: [Session]) async throws {}

    func deleteAllUserData(knownSessionIDs: [Int64]) async throws {
        if let deleteAllUserDataError {
            throw deleteAllUserDataError
        }
    }

    func hasAnyUserData() async throws -> Bool {
        if let hasAnyUserDataError {
            throw hasAnyUserDataError
        }
        return hasAnyUserDataResult
    }
}
