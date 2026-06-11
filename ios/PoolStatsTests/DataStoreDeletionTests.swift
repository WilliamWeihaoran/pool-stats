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

        XCTAssertEqual(store.sessions.map(\.id), [session.id])
        XCTAssertTrue(store.lastError?.contains("Session history cleanup did not complete, so local history was kept. Please try again when iCloud is available.") == true)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: pendingAccountDeletionCleanupKey))
        if case .localOnly(let message) = store.syncStatus {
            XCTAssertTrue(message.contains("Session history cleanup did not complete, so local history was kept. Please try again when iCloud is available."))
        } else {
            XCTFail("Expected localOnly status after real iCloud delete failure.")
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: localCache.url.path))
    }

    func testDeleteAccountKeepsLocalHistoryWhenCloudVerificationIsInconclusive() async {
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

        XCTAssertEqual(store.sessions.map(\.id), [session.id])
        XCTAssertTrue(store.lastError?.contains("Session history cleanup did not complete, so local history was kept. Please try again when iCloud is available.") == true)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: pendingAccountDeletionCleanupKey))
        let deletedStore = DeletedSessionIDStore(url: tempDir.appendingPathComponent("deleted-session-ids.json"))
        XCTAssertTrue(deletedStore.load().isEmpty)
        if case .localOnly(let message) = store.syncStatus {
            XCTAssertTrue(message.contains("Session history cleanup did not complete, so local history was kept. Please try again when iCloud is available."))
        } else {
            XCTFail("Expected localOnly status after unverified delete.")
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: localCache.url.path))
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

        XCTAssertEqual(store.sessions.map(\.id), [4])
        XCTAssertFalse(UserDefaults.standard.bool(forKey: pendingAccountDeletionCleanupKey))
        XCTAssertTrue(store.lastError?.contains("iCloud still reports remaining session history after the delete request.") == true)
    }

    func testDeleteAccountPreflightFailureDoesNotDeleteLocalHistory() async {
        let service = FakeSessionService()
        service.verifyAccountDeletionReadinessError = FakeError.sample
        let (store, localCache, tempDir) = makeStore(service: service)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let session = makeSession(id: 7, ts: Date(timeIntervalSince1970: 7_000), racks: [makeRack(index: 1)])
        localCache.saveSessions([session])
        store.sessions = [session]

        do {
            try await store.verifyAccountDeletionReadinessForAccountDeletion()
            XCTFail("Expected preflight to throw before deletion.")
        } catch {
        }

        XCTAssertEqual(store.sessions.map(\.id), [session.id])
        XCTAssertEqual(service.deleteAllUserDataCallCount, 0)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: pendingAccountDeletionCleanupKey))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localCache.url.path))
        XCTAssertTrue(store.lastError?.contains("Session history cleanup cannot start because iCloud could not be verified. No data was deleted.") == true)
    }

    func testPendingAccountDeletionRefreshDoesNotRehydrateCloudSessionsWhenCleanupStillPending() async {
        UserDefaults.standard.set(true, forKey: pendingAccountDeletionCleanupKey)
        let service = FakeSessionService()
        service.deleteAllUserDataError = FakeError.sample
        service.hasAnyUserDataResult = true
        service.fetchedSessions = [makeSession(id: 5, ts: Date(timeIntervalSince1970: 5_000), racks: [makeRack(index: 1)])]
        let (store, localCache, tempDir) = makeStore(service: service)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let localSession = makeSession(id: 8, ts: Date(timeIntervalSince1970: 8_000), racks: [makeRack(index: 1)])
        localCache.saveSessions([localSession])
        store.sessions = [localSession]

        await store.refresh()

        XCTAssertEqual(store.sessions.map(\.id), [localSession.id])
        XCTAssertEqual(service.fetchAllSessionsCallCount, 0)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: pendingAccountDeletionCleanupKey))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localCache.url.path))
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

    func testImportJSONKeepsImportedSessionsLocallyWhenCloudSyncFails() async throws {
        let service = FakeSessionService()
        service.replaceAllSessionsError = FakeError.sample
        let (store, localCache, tempDir) = makeStore(service: service)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let session = makeSession(id: 9, ts: Date(timeIntervalSince1970: 9_000), racks: [makeRack(index: 1)])
        let data = try JSONTransfer.exportSessions([session])

        await store.importJSON(data)

        XCTAssertEqual(store.sessions.map(\.id), [session.id])
        XCTAssertEqual(localCache.loadSessions().map(\.id), [session.id])
        XCTAssertEqual(service.replaceAllSessionsCallCount, 1)
        XCTAssertTrue(store.lastError?.contains("Imported sessions are saved locally. iCloud sync failed.") == true)
        if case .localOnly(let message) = store.syncStatus {
            XCTAssertTrue(message.contains("Imported sessions are saved locally. iCloud sync failed."))
        } else {
            XCTFail("Expected localOnly status when import sync fails.")
        }
    }

    func testRefreshKeepsLocalOnlyErrorWhenLocalCacheReuploadFails() async {
        let service = FakeSessionService()
        service.fetchedSessions = []
        service.replaceAllSessionsError = FakeError.sample
        let (store, localCache, tempDir) = makeStore(service: service)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let session = makeSession(id: 10, ts: Date(timeIntervalSince1970: 10_000), racks: [makeRack(index: 1)])
        localCache.saveSessions([session])
        store.sessions = [session]

        await store.refresh()

        XCTAssertEqual(store.sessions.map(\.id), [session.id])
        XCTAssertEqual(service.replaceAllSessionsCallCount, 1)
        XCTAssertTrue(store.lastError?.contains("Local sessions are saved on this device. iCloud sync failed.") == true)
        XCTAssertTrue(store.lastSyncFailureReason?.contains("Local sessions are saved on this device. iCloud sync failed.") == true)
        if case .localOnly(let message) = store.syncStatus {
            XCTAssertTrue(message.contains("Local sessions are saved on this device. iCloud sync failed."))
        } else {
            XCTFail("Expected localOnly status when local cache reupload fails.")
        }
    }

    func testHasLocalAccountDeletionDataTracksVisibleLocalSessions() {
        let service = FakeSessionService()
        let (store, _, tempDir) = makeStore(service: service)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        XCTAssertFalse(store.hasLocalAccountDeletionData)

        store.sessions = [makeSession(id: 11, ts: Date(timeIntervalSince1970: 11_000), racks: [makeRack(index: 1)])]

        XCTAssertTrue(store.hasLocalAccountDeletionData)
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
    var verifyAccountDeletionReadinessError: Error?
    var deleteAllUserDataError: Error?
    var hasAnyUserDataError: Error?
    var replaceAllSessionsError: Error?
    var hasAnyUserDataResult = false
    var fetchedSessions: [Session] = []
    var fetchAllSessionsCallCount = 0
    var deleteAllUserDataCallCount = 0
    var replaceAllSessionsCallCount = 0

    func fetchAllSessions() async throws -> [Session] {
        fetchAllSessionsCallCount += 1
        return fetchedSessions
    }
    func saveSession(_ session: Session) async throws {}
    func updateSessionMeta(_ session: Session) async throws {}
    func deleteSessions(_ ids: [Int64]) async throws {}
    func replaceAllSessions(existingIDs: [Int64], with newSessions: [Session]) async throws {
        replaceAllSessionsCallCount += 1
        if let replaceAllSessionsError {
            throw replaceAllSessionsError
        }
    }

    func verifyAccountDeletionReadiness(knownSessionIDs: [Int64]) async throws {
        if let verifyAccountDeletionReadinessError {
            throw verifyAccountDeletionReadinessError
        }
    }

    func deleteAllUserData(knownSessionIDs: [Int64]) async throws {
        deleteAllUserDataCallCount += 1
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
