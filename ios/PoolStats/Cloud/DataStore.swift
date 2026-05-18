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

    private let service = SessionService()
    private let seedFlagKey = "didSeedSampleData"
    private let localURL: URL
    private let deletedSessionIDsURL: URL
    private var deletedSessionIDs: Set<Int64> = []

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("PoolStats", isDirectory: true)
        localURL = dir.appendingPathComponent("sessions.json")
        deletedSessionIDsURL = dir.appendingPathComponent("deleted-session-ids.json")
        loadDeletedSessionIDs()
        loadLocal()
        sessions.removeAll { deletedSessionIDs.contains($0.id) }
        syncStatus = sessions.isEmpty ? .loading : .localOnly("Loaded local cache")
        Task { await refresh() }
    }

    func refresh() async {
        markSyncAttempt()
        isLoading = true
        syncStatus = .syncing
        defer { isLoading = false }
        let localSnapshot = sessions.filter { !deletedSessionIDs.contains($0.id) }
        do {
            await retryPendingCloudDeletes()
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

    func exportJSON() -> Data? {
        JSONTransfer.exportSessions(sessions)
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
            lastError = error.localizedDescription
            syncStatus = .error("Import failed")
            markSyncFailure("Import failed")
        }
    }

    func restoreSampleData() async {
        markSyncAttempt()
        let sample = SampleData.makeSessions()
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

    private func replaceAllSessions(_ newSessions: [Session]) async throws {
        let existingIDs = existingIDsIncludingPendingDeletes()
        try await service.replaceAllSessions(existingIDs: existingIDs, with: newSessions)
        clearDeletedSessionIDs()
        sessions = newSessions
        saveLocal()
    }

    private func seedIfNeeded() async {
        guard sessions.isEmpty else { return }
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
        if UserDefaults.standard.bool(forKey: seedFlagKey) { return }
        sessions = SampleData.makeSessions()
        saveLocal()
        UserDefaults.standard.set(true, forKey: seedFlagKey)
        syncStatus = .localOnly("Using local sample data")
    }

    private func loadLocal() {
        guard let data = try? Data(contentsOf: localURL) else { return }
        if let loaded = try? JSONTransfer.importSessions(data) {
            sessions = loaded
        }
    }

    private func saveLocal() {
        guard let data = JSONTransfer.exportSessions(sessions) else { return }
        let dir = localURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: localURL, options: .atomic)
    }

    private func loadDeletedSessionIDs() {
        guard let data = try? Data(contentsOf: deletedSessionIDsURL),
              let ids = try? JSONDecoder().decode([Int64].self, from: data) else { return }
        deletedSessionIDs = Set(ids)
    }

    private func saveDeletedSessionIDs() {
        let dir = deletedSessionIDsURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        guard !deletedSessionIDs.isEmpty else {
            try? FileManager.default.removeItem(at: deletedSessionIDsURL)
            return
        }
        let ids = Array(deletedSessionIDs).sorted()
        guard let data = try? JSONEncoder().encode(ids) else { return }
        try? data.write(to: deletedSessionIDsURL, options: .atomic)
    }

    private func clearDeletedSessionIDs() {
        deletedSessionIDs.removeAll()
        saveDeletedSessionIDs()
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
}
