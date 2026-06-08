import Foundation
import Combine

@MainActor
final class DataStore: ObservableObject {
    enum SyncStatus {
        case loading
        case syncing
        case synced
        case localOnly(String)
        case error(String)
    }

    @Published var sessions: [Session] = []
    @Published var isLoading: Bool = false
    @Published var lastError: String?
    @Published var syncStatus: SyncStatus = .loading
    @Published var lastSyncAttemptAt: Date?
    @Published var lastSyncSuccessAt: Date?
    @Published var lastSyncFailureReason: String?

    private let service: any SessionServicing
    private let seedFlagKey = "didSeedSampleData"
    private let suppressAutoSeedKey = "suppressAutomaticSampleSeed"
    private let pendingAccountDeletionCleanupKey = "pendingAccountDeletionCloudCleanup"
    private let pendingAccountDeletionMessage = NSLocalizedString("Account deletion will finish when iCloud is available.", comment: "")
    private let failedAccountDeletionMessage = NSLocalizedString("Deleted local session history. iCloud cleanup failed.", comment: "")
    private let localCache: LocalSessionCache
    private let deletedSessionIDStore: DeletedSessionIDStore
    private var deletedSessionIDs: Set<Int64> = []

    init(
        service: any SessionServicing = SessionService(),
        localCache: LocalSessionCache = LocalSessionCache(),
        deletedSessionIDStore: DeletedSessionIDStore = DeletedSessionIDStore(),
        autoRefresh: Bool = true
    ) {
        self.service = service
        self.localCache = localCache
        self.deletedSessionIDStore = deletedSessionIDStore
        deletedSessionIDs = deletedSessionIDStore.load()
        loadLocal()
        sessions.removeAll { deletedSessionIDs.contains($0.id) }
        syncStatus = sessions.isEmpty ? .loading : .localOnly("Loaded local cache")
        if autoRefresh {
            Task { await refresh() }
        }
    }

    func refresh() async {
        markSyncAttempt()
        isLoading = true
        syncStatus = .syncing
        defer { isLoading = false }
        let localSnapshot = sessions.filter { !deletedSessionIDs.contains($0.id) }
        do {
            await retryPendingCloudDeletes()
            guard await retryPendingAccountDeletionCleanupIfNeeded() else { return }
            let fetched = try await service.fetchAllSessions()
            let visibleFetched = fetched.filter { !deletedSessionIDs.contains($0.id) }
            if visibleFetched.isEmpty && !localSnapshot.isEmpty {
                sessions = localSnapshot
                do {
                    try await service.replaceAllSessions(existingIDs: [], with: localSnapshot)
                    syncStatus = .synced
                    markSyncSuccess()
                } catch {
                    syncStatus = .localOnly("Saved locally. iCloud sync failed.")
                    markSyncFailure("Saved locally. iCloud sync failed.")
                }
            } else {
                sessions = mergeCloudAndLocal(cloud: visibleFetched, local: localSnapshot)
                syncStatus = .synced
                markSyncSuccess()
            }
            saveLocal()
            lastError = nil
            await seedIfNeeded()
        } catch {
            lastError = error.localizedDescription
            markSyncFailure(error.localizedDescription)
            if sessions.isEmpty {
                await seedFallback()
                syncStatus = .localOnly("Using local sample data")
            } else {
                syncStatus = .localOnly("Offline: using local cache")
            }
        }
    }

    func saveSession(_ session: Session) async {
        markSyncAttempt()
        syncStatus = .syncing
        setAutoSeedSuppressed(false)
        do {
            try await service.saveSession(session)
            upsertSession(session)
            saveLocal()
            lastError = nil
            syncStatus = .synced
            markSyncSuccess()
        } catch {
            upsertSession(session)
            saveLocal()
            lastError = "Saved locally. iCloud sync failed."
            syncStatus = .localOnly("Saved locally. iCloud sync failed.")
            markSyncFailure("Saved locally. iCloud sync failed.")
        }
    }

    func updateSessionLabel(sessionID: Int64, label: String) async {
        markSyncAttempt()
        guard var sess = sessions.first(where: { $0.id == sessionID }) else { return }
        sess.label = label
        do {
            try await service.updateSessionMeta(sess)
            if let idx = sessions.firstIndex(where: { $0.id == sessionID }) {
                sessions[idx] = sess
            } else {
                sessions.append(sess)
            }
            saveLocal()
            syncStatus = .synced
            lastError = nil
            markSyncSuccess()
        } catch {
            lastError = error.localizedDescription
            syncStatus = .localOnly("Updated locally. iCloud sync failed.")
            markSyncFailure("Updated locally. iCloud sync failed.")
            if let idx = sessions.firstIndex(where: { $0.id == sessionID }) {
                sessions[idx] = sess
                saveLocal()
            }
        }
    }

    func updateSessionMeta(sessionID: Int64, label: String? = nil, opponent: String? = nil, performanceRating: Int? = nil) async {
        markSyncAttempt()
        guard var sess = sessions.first(where: { $0.id == sessionID }) else { return }
        if let label { sess.label = label }
        if let opponent { sess.opponent = opponent }
        if let performanceRating { sess.performanceRating = performanceRating }
        do {
            try await service.updateSessionMeta(sess)
            if let idx = sessions.firstIndex(where: { $0.id == sessionID }) {
                sessions[idx] = sess
            } else {
                sessions.append(sess)
            }
            saveLocal()
            syncStatus = .synced
            lastError = nil
            markSyncSuccess()
        } catch {
            lastError = error.localizedDescription
            syncStatus = .localOnly("Updated locally. iCloud sync failed.")
            markSyncFailure("Updated locally. iCloud sync failed.")
            if let idx = sessions.firstIndex(where: { $0.id == sessionID }) {
                sessions[idx] = sess
                saveLocal()
            }
        }
    }

    func deleteSessions(ids: [Int64]) async {
        guard !ids.isEmpty else { return }
        markSyncAttempt()
        deletedSessionIDs.formUnion(ids)
        saveDeletedSessionIDs()
        // Apply delete locally first so History reflects user intent immediately.
        sessions.removeAll { ids.contains($0.id) }
        saveLocal()
        do {
            try await service.deleteSessions(ids)
            deletedSessionIDs.subtract(ids)
            saveDeletedSessionIDs()
            lastError = nil
            syncStatus = .synced
            markSyncSuccess()
        } catch {
            lastError = error.localizedDescription
            syncStatus = .localOnly("Deleted locally. iCloud delete failed.")
            markSyncFailure("Deleted locally. iCloud delete failed.")
        }
    }

    func exportJSON() throws -> Data {
        try JSONTransfer.exportSessions(sessions)
    }

    func importJSON(_ data: Data) async {
        markSyncAttempt()
        do {
            let newSessions = try JSONTransfer.importSessions(data)
            try await replaceAllSessions(newSessions)
            lastError = nil
            syncStatus = .synced
            markSyncSuccess()
        } catch {
            let message = error.localizedDescription
            lastError = message
            syncStatus = .error(message)
            markSyncFailure(message)
        }
    }

    func restoreSampleData() async {
        markSyncAttempt()
        let sample = SampleData.makeSessions()
        setAutoSeedSuppressed(false)
        do {
            let existingIDs = existingIDsIncludingPendingDeletes()
            try await service.replaceAllSessions(existingIDs: existingIDs, with: sample)
            clearDeletedSessionIDs()
            sessions = sample
            saveLocal()
            UserDefaults.standard.set(true, forKey: seedFlagKey)
            lastError = nil
            syncStatus = .synced
            markSyncSuccess()
        } catch {
            clearDeletedSessionIDs()
            sessions = sample
            saveLocal()
            UserDefaults.standard.set(true, forKey: seedFlagKey)
            lastError = error.localizedDescription
            syncStatus = .localOnly("Sample data saved locally only")
            markSyncFailure("Sample data saved locally only")
        }
    }

    func deleteAllUserDataForAccountDeletion() async throws {
        markSyncAttempt()
        syncStatus = .syncing

        let knownIDs = existingIDsIncludingPendingDeletes()
        do {
            try await service.deleteAllUserData(knownSessionIDs: knownIDs)
            switch await remoteDeletionVerificationState() {
            case .absent:
                finishVerifiedAccountDeletionCleanup()
            case .present:
                persistPendingAccountDeletionCleanup(knownIDs: knownIDs, message: failedAccountDeletionMessage)
                throw AccountDeletionCleanupError.remoteDataStillExists
            case .unknown:
                persistPendingAccountDeletionCleanup(knownIDs: knownIDs, message: pendingAccountDeletionMessage)
                throw AccountDeletionCleanupError.remoteVerificationUnavailable
            }
        } catch {
            switch await remoteDeletionVerificationState() {
            case .absent:
                finishVerifiedAccountDeletionCleanup()
            case .present:
                persistPendingAccountDeletionCleanup(knownIDs: knownIDs, message: failedAccountDeletionMessage)
                throw error
            case .unknown:
                persistPendingAccountDeletionCleanup(knownIDs: knownIDs, message: pendingAccountDeletionMessage)
                throw error
            }
        }
    }

    private func replaceAllSessions(_ newSessions: [Session]) async throws {
        let existingIDs = existingIDsIncludingPendingDeletes()
        try await service.replaceAllSessions(existingIDs: existingIDs, with: newSessions)
        clearDeletedSessionIDs()
        sessions = newSessions
        saveLocal()
    }

    private func seedIfNeeded() async {
        guard sessions.isEmpty else { return }
        if UserDefaults.standard.bool(forKey: suppressAutoSeedKey) { return }
        if UserDefaults.standard.bool(forKey: seedFlagKey) { return }
        let sample = SampleData.makeSessions()
        do {
            sessions = sample
            try await service.replaceAllSessions(existingIDs: [], with: sample)
            saveLocal()
            UserDefaults.standard.set(true, forKey: seedFlagKey)
            syncStatus = .synced
        } catch {
            lastError = error.localizedDescription
            syncStatus = .localOnly("Loaded local sample data")
        }
    }

    private func seedFallback() async {
        guard sessions.isEmpty else { return }
        if UserDefaults.standard.bool(forKey: suppressAutoSeedKey) { return }
        if UserDefaults.standard.bool(forKey: seedFlagKey) { return }
        sessions = SampleData.makeSessions()
        saveLocal()
        UserDefaults.standard.set(true, forKey: seedFlagKey)
        syncStatus = .localOnly("Using local sample data")
    }

    private func loadLocal() {
        sessions = localCache.loadSessions()
    }

    private func saveLocal() {
        localCache.saveSessions(sessions)
    }

    private func saveDeletedSessionIDs() {
        deletedSessionIDStore.save(deletedSessionIDs)
    }

    private func clearDeletedSessionIDs() {
        deletedSessionIDs.removeAll()
        saveDeletedSessionIDs()
    }

    private func clearLocalDataForAccountDeletion(pendingCloudDeleteIDs: [Int64] = []) {
        sessions = []
        deletedSessionIDs = Set(pendingCloudDeleteIDs)
        saveDeletedSessionIDs()
        setAutoSeedSuppressed(true)
        localCache.clear()
        lastSyncSuccessAt = nil
        lastSyncFailureReason = nil
    }

    private func finishVerifiedAccountDeletionCleanup() {
        clearLocalDataForAccountDeletion()
        setPendingAccountDeletionCleanup(false)
        lastError = nil
        syncStatus = .synced
        markSyncSuccess()
    }

    private func persistPendingAccountDeletionCleanup(knownIDs: [Int64], message: String) {
        clearLocalDataForAccountDeletion(pendingCloudDeleteIDs: knownIDs)
        setPendingAccountDeletionCleanup(true)
        lastError = message
        syncStatus = .localOnly(message)
        markSyncFailure(message)
    }

    private func retryPendingAccountDeletionCleanupIfNeeded() async -> Bool {
        guard UserDefaults.standard.bool(forKey: pendingAccountDeletionCleanupKey) else {
            return true
        }

        do {
            try await service.deleteAllUserData(knownSessionIDs: existingIDsIncludingPendingDeletes())
            switch await remoteDeletionVerificationState() {
            case .absent:
                finishVerifiedAccountDeletionCleanup()
                // Stop this refresh cycle so stale CloudKit query results cannot rehydrate
                // just-deleted sessions immediately after cleanup succeeds.
                return false
            case .present:
                throw AccountDeletionCleanupError.remoteDataStillExists
            case .unknown:
                throw AccountDeletionCleanupError.remoteVerificationUnavailable
            }
        } catch {
            sessions = []
            localCache.clear()
            setAutoSeedSuppressed(true)
            setPendingAccountDeletionCleanup(true)
            lastError = pendingAccountDeletionMessage
            syncStatus = .localOnly(pendingAccountDeletionMessage)
            markSyncFailure(pendingAccountDeletionMessage)
            return false
        }
    }

    private func remoteDeletionVerificationState() async -> RemoteDeletionVerificationState {
        do {
            return try await service.hasAnyUserData() ? .present : .absent
        } catch {
            return .unknown
        }
    }

    private func retryPendingCloudDeletes() async {
        guard !deletedSessionIDs.isEmpty else { return }
        let ids = Array(deletedSessionIDs)
        do {
            try await service.deleteSessions(ids)
            deletedSessionIDs.removeAll()
            saveDeletedSessionIDs()
        } catch {
            // Keep tombstones so failed cloud deletes do not reappear locally on refresh.
        }
    }

    private func mergeCloudAndLocal(cloud: [Session], local: [Session]) -> [Session] {
        var merged = cloud
        for session in local where !deletedSessionIDs.contains(session.id) {
            let alreadyFetched = merged.contains {
                $0.sessionUUID == session.sessionUUID || $0.id == session.id
            }
            if !alreadyFetched {
                merged.append(session)
            }
        }
        return merged.sorted(by: Session.oldestFirst)
    }

    private func existingIDsIncludingPendingDeletes() -> [Int64] {
        Array(Set(sessions.map { $0.id }).union(deletedSessionIDs))
    }

    private func upsertSession(_ session: Session) {
        if let idx = sessions.firstIndex(where: { $0.sessionUUID == session.sessionUUID }) {
            sessions[idx] = session
        } else if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[idx] = session
        } else {
            sessions.append(session)
        }
    }

    private func markSyncAttempt() {
        lastSyncAttemptAt = Date()
    }

    private func markSyncSuccess() {
        lastSyncSuccessAt = Date()
        lastSyncFailureReason = nil
    }

    private func markSyncFailure(_ reason: String) {
        lastSyncFailureReason = reason
    }

    private func setAutoSeedSuppressed(_ suppressed: Bool) {
        UserDefaults.standard.set(suppressed, forKey: suppressAutoSeedKey)
    }

    private func setPendingAccountDeletionCleanup(_ pending: Bool) {
        if pending {
            UserDefaults.standard.set(true, forKey: pendingAccountDeletionCleanupKey)
        } else {
            UserDefaults.standard.removeObject(forKey: pendingAccountDeletionCleanupKey)
        }
    }

    private enum AccountDeletionCleanupError: Error {
        case remoteDataStillExists
        case remoteVerificationUnavailable
    }

    private enum RemoteDeletionVerificationState {
        case present
        case absent
        case unknown
    }
}
