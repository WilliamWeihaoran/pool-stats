import Foundation
import Combine
import WatchConnectivity

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

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("PoolStats", isDirectory: true)
        localURL = dir.appendingPathComponent("sessions.json")
        loadLocal()
        syncStatus = sessions.isEmpty ? .loading : .localOnly("Loaded local cache")
        Task { await refresh() }
    }

    func refresh() async {
        markSyncAttempt()
        isLoading = true
        syncStatus = .syncing
        defer { isLoading = false }
        let localSnapshot = sessions
        do {
            let fetched = try await service.fetchAllSessions()
            if fetched.isEmpty && !localSnapshot.isEmpty {
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
                sessions = fetched
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
            sessions.append(session)
            saveLocal()
            lastError = nil
            syncStatus = .synced
            markSyncSuccess()
        } catch {
            sessions.append(session)
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
        // Apply delete locally first so History reflects user intent immediately.
        sessions.removeAll { ids.contains($0.id) }
        saveLocal()
        do {
            try await service.deleteSessions(ids)
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
            let existingIDs = sessions.map { $0.id }
            try await service.replaceAllSessions(existingIDs: existingIDs, with: sample)
            sessions = sample
            saveLocal()
            UserDefaults.standard.set(true, forKey: seedFlagKey)
            lastError = nil
            syncStatus = .synced
            markSyncSuccess()
        } catch {
            sessions = sample
            saveLocal()
            UserDefaults.standard.set(true, forKey: seedFlagKey)
            lastError = error.localizedDescription
            syncStatus = .localOnly("Sample data saved locally only")
            markSyncFailure("Sample data saved locally only")
        }
    }

    private func replaceAllSessions(_ newSessions: [Session]) async throws {
        let existingIDs = sessions.map { $0.id }
        try await service.replaceAllSessions(existingIDs: existingIDs, with: newSessions)
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

// MARK: - Watch sync (phone side)

enum WatchSyncAction: String, Codable {
    case startSession = "start_session"
    case attachActiveSession = "attach_active_session"
    case rackPatch = "rack_patch"
    case saveRack = "save_rack"
    case undoLastRack = "undo_last_rack"
    case discardSession = "discard_session"
    case endSessionWithRating = "end_session_with_rating"
    case sessionSnapshot = "session_snapshot"
    case ack = "ack"
}

struct WatchSessionStartPayload: Codable, Hashable {
    var game: String
    var type: String
    var opponent: String
    var timestampMs: Int64?
}

struct WatchEndSessionPayload: Codable, Hashable {
    var rating: Int
}

struct WatchSyncEnvelope: Codable, Hashable {
    var version: Int = 1
    var action: WatchSyncAction
    var sessionUUID: String?
    var rackUUID: String?
    var patch: WatchRackPatch?
    var start: WatchSessionStartPayload?
    var end: WatchEndSessionPayload?
    var sentAtMs: Int64
}

struct WatchSessionSnapshot: Codable, Hashable {
    var active: ActiveSessionSnapshot?
    var availableOpponents: [String]
    var acknowledgedAtMs: Int64
    var message: String?
}

@MainActor
final class WatchSyncStore: NSObject, ObservableObject {
    @Published private(set) var isReachable: Bool = false

    private weak var dataStore: DataStore?
    private weak var logStore: SessionLogStore?
    private weak var opponentStore: OpponentStore?
    private var cancellables: Set<AnyCancellable> = []

    func bind(dataStore: DataStore, logStore: SessionLogStore, opponentStore: OpponentStore) {
        self.dataStore = dataStore
        self.logStore = logStore
        self.opponentStore = opponentStore
        activateSessionIfNeeded()

        logStore.$currentSession
            .combineLatest(logStore.$currentRack)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _ in
                self?.pushSnapshot(message: nil)
            }
            .store(in: &cancellables)
    }

    private func activateSessionIfNeeded() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        isReachable = session.isReachable
    }

    private func nowMs() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }

    private func availableOpponents() -> [String] {
        guard let dataStore, let opponentStore else { return ["Other"] }
        var names = opponentStore.availableNames(from: dataStore.sessions).filter { $0 != "All opponents" }
        if names.contains(where: { $0.caseInsensitiveCompare("Other") == .orderedSame }) == false {
            names.append("Other")
        }
        return names
    }

    private func makeSnapshot(message: String?) -> WatchSessionSnapshot {
        WatchSessionSnapshot(
            active: logStore?.activeSnapshot,
            availableOpponents: availableOpponents(),
            acknowledgedAtMs: nowMs(),
            message: message
        )
    }

    private func payload(for snapshot: WatchSessionSnapshot) -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(snapshot),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return obj
    }

    private func envelope(from message: [String: Any]) -> WatchSyncEnvelope? {
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let env = try? JSONDecoder().decode(WatchSyncEnvelope.self, from: data) else { return nil }
        return env
    }

    private func pushSnapshot(message: String?) {
        guard WCSession.isSupported() else { return }
        let snapshot = makeSnapshot(message: message)
        guard let payload = payload(for: snapshot) else { return }
        let session = WCSession.default
        if session.isReachable {
            session.sendMessage(
                ["action": WatchSyncAction.sessionSnapshot.rawValue, "snapshot": payload],
                replyHandler: nil,
                errorHandler: nil
            )
        } else {
            try? session.updateApplicationContext(
                ["action": WatchSyncAction.sessionSnapshot.rawValue, "snapshot": payload]
            )
        }
    }

    private func handle(_ env: WatchSyncEnvelope) {
        guard let logStore else { return }
        switch env.action {
        case .attachActiveSession:
            pushSnapshot(message: "attached")

        case .startSession:
            guard let start = env.start else { return }
            // Dedup: if this session is already active (queue replay), don't restart it.
            if let uuid = env.sessionUUID, logStore.matchesActiveSession(uuid) {
                pushSnapshot(message: "already_active")
                return
            }
            let date = start.timestampMs.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) } ?? Date()
            logStore.startSession(
                game: start.game,
                type: start.type,
                label: "",
                opponent: start.opponent,
                date: date,
                sessionUUID: env.sessionUUID
            )
            pushSnapshot(message: "session_started")

        case .rackPatch:
            guard let patch = env.patch else { return }
            guard logStore.matchesActiveSession(env.sessionUUID), logStore.matchesActiveRack(env.rackUUID) else {
                pushSnapshot(message: "stale_patch_ignored")
                return
            }
            logStore.applyRemotePatch(patch)
            pushSnapshot(message: "rack_patched")

        case .saveRack:
            guard logStore.matchesActiveSession(env.sessionUUID), logStore.matchesActiveRack(env.rackUUID) else {
                pushSnapshot(message: "stale_save_ignored")
                return
            }
            _ = logStore.saveRackFromRemote()
            pushSnapshot(message: "rack_saved")

        case .undoLastRack:
            guard logStore.matchesActiveSession(env.sessionUUID) else {
                pushSnapshot(message: "stale_undo_ignored")
                return
            }
            _ = logStore.undoLastRackFromRemote()
            pushSnapshot(message: "rack_undone")

        case .discardSession:
            guard logStore.matchesActiveSession(env.sessionUUID) else {
                pushSnapshot(message: "stale_discard_ignored")
                return
            }
            logStore.discardSession()
            pushSnapshot(message: "session_discarded")

        case .endSessionWithRating:
            guard let end = env.end, let dataStore else { return }
            guard logStore.matchesActiveSession(env.sessionUUID) else {
                pushSnapshot(message: "stale_end_ignored")
                return
            }
            Task {
                await logStore.endSessionFromRemote(rating: end.rating, savingTo: dataStore)
                await MainActor.run {
                    self.pushSnapshot(message: "session_ended")
                }
            }

        case .sessionSnapshot, .ack:
            break
        }
    }
}

extension WatchSyncStore: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            self.pushSnapshot(message: nil)
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            if session.isReachable { self.pushSnapshot(message: nil) }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            guard let env = self.envelope(from: message) else { return }
            self.handle(env)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            if let action = applicationContext["action"] as? String, action == WatchSyncAction.sessionSnapshot.rawValue {
                return
            }
            guard let env = self.envelope(from: applicationContext) else { return }
            self.handle(env)
        }
    }
}
