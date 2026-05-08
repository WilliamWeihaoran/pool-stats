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
    private let deletedSessionIDsURL: URL
    private var deletedSessionIDs: Set<Int64> = []

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
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

// MARK: - Watch sync (phone side)

enum WatchSyncAction: String, Codable {
    case startSession = "start_session"
    case attachActiveSession = "attach_active_session"
    case rackPatch = "rack_patch"
    case saveRack = "save_rack"
    case undoLastRack = "undo_last_rack"
    case discardSession = "discard_session"
    case endSessionWithRating = "end_session_with_rating"
    case drillAttempt = "drill_attempt"
    case drillDifficulty = "drill_difficulty"
    case sessionSnapshot = "session_snapshot"
    case ack = "ack"
}

struct WatchSessionStartPayload: Codable, Hashable {
    var game: String
    var type: String
    var opponent: String
    var drillID: String?
    var targetType: String?
    var targetCount: Int?
    var drillDifficulty: String?
    var drillBallCount: Int?
    var timestampMs: Int64?
}

struct WatchEndSessionPayload: Codable, Hashable {
    var rating: Int
}

struct WatchDrillAttemptPayload: Codable, Hashable {
    var outcome: String
    var tags: [String]
    var ballsMade: Int
    var targetBallCount: Int
    var difficulty: String
    var saveAndExit: Bool
}

struct WatchDrillDifficultyPayload: Codable, Hashable {
    var difficulty: String
    var ballCount: Int
}

struct WatchDrillTemplateDifficultyPayload: Codable, Hashable {
    var level: String
    var label: String
    var ballCount: Int
    var constraint: String
}

struct WatchDrillTemplatePayload: Codable, Hashable {
    var id: String
    var title: String
    var details: String
    var countUnit: String? = nil
    var difficultyLevels: [WatchDrillTemplateDifficultyPayload]
}

struct WatchSyncEnvelope: Codable, Hashable {
    var version: Int = 1
    var action: WatchSyncAction
    var sessionUUID: String?
    var rackUUID: String?
    var patch: WatchRackPatch?
    var start: WatchSessionStartPayload?
    var end: WatchEndSessionPayload?
    var drillAttempt: WatchDrillAttemptPayload?
    var drillDifficulty: WatchDrillDifficultyPayload?
    var sentAtMs: Int64
}


struct WatchSessionSnapshot: Codable, Hashable {
    var active: ActiveSessionSnapshot?
    var availableOpponents: [String]
    var availableDrills: [WatchDrillTemplatePayload]
    var clearedSessionUUID: String? = nil
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
    private var lastKnownActiveSessionUUID: String?
    private var lastClearedSessionUUID: String?

    func bind(dataStore: DataStore, logStore: SessionLogStore, opponentStore: OpponentStore) {
        self.dataStore = dataStore
        self.logStore = logStore
        self.opponentStore = opponentStore
        activateSessionIfNeeded()

        logStore.$currentSession
            .combineLatest(logStore.$currentRack)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session, _ in
                guard let self else { return }
                let message: String?
                if let session {
                    self.lastKnownActiveSessionUUID = session.sessionUUID
                    self.lastClearedSessionUUID = nil
                    message = nil
                } else if self.lastKnownActiveSessionUUID != nil {
                    self.lastClearedSessionUUID = self.lastKnownActiveSessionUUID
                    self.lastKnownActiveSessionUUID = nil
                    message = "session_cleared"
                } else {
                    message = nil
                }
                self.pushSnapshot(message: message)
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

    private func availableDrills() -> [WatchDrillTemplatePayload] {
        DrillLibrary.templates.map { template in
            WatchDrillTemplatePayload(
                id: template.id,
                title: template.title,
                details: template.description,
                countUnit: template.countUnit.rawValue,
                difficultyLevels: template.difficultyLevels.map { difficulty in
                    WatchDrillTemplateDifficultyPayload(
                        level: difficulty.level.rawValue,
                        label: difficulty.level.label,
                        ballCount: difficulty.ballCount,
                        constraint: difficulty.constraint
                    )
                }
            )
        }
    }

    private func makeSnapshot(message: String?) -> WatchSessionSnapshot {
        WatchSessionSnapshot(
            active: logStore?.activeSnapshotForWatch,
            availableOpponents: availableOpponents(),
            availableDrills: availableDrills(),
            clearedSessionUUID: logStore?.activeSnapshotForWatch == nil ? lastClearedSessionUUID : nil,
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
        try? session.updateApplicationContext(
            ["action": WatchSyncAction.sessionSnapshot.rawValue, "snapshot": payload]
        )
        if session.isReachable {
            session.sendMessage(
                ["action": WatchSyncAction.sessionSnapshot.rawValue, "snapshot": payload],
                replyHandler: nil,
                errorHandler: nil
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
            if logStore.currentSession != nil {
                pushSnapshot(message: "active_session_exists")
                return
            }
            if start.type == "practice", let drillID = start.drillID, let template = DrillLibrary.template(id: drillID) {
                let fallbackDifficulty = template.standardDifficulty
                let resolvedDifficulty: DrillDifficulty = {
                    guard let raw = start.drillDifficulty,
                          let level = DrillDifficultyLevel(rawValue: raw),
                          let specific = template.difficultyLevels.first(where: { $0.level == level }) else {
                        return fallbackDifficulty
                    }
                    let chosenCount = start.drillBallCount ?? specific.ballCount
                    return DrillDifficulty(level: specific.level, ballCount: chosenCount, constraint: specific.constraint)
                }()

                logStore.startDrillPractice(
                    template: template,
                    difficulty: resolvedDifficulty,
                    targetType: start.targetType ?? "successes",
                    targetCount: start.targetCount ?? 3,
                    sessionUUID: env.sessionUUID
                )
                pushSnapshot(message: "drill_session_started")
            } else {
                let date = start.timestampMs.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) } ?? Date()
                logStore.startSession(
                    game: start.game,
                    label: "",
                    opponent: start.opponent,
                    date: date,
                    sessionUUID: env.sessionUUID
                )
                pushSnapshot(message: "session_started")
            }

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
            if let patch = env.patch {
                logStore.applyRemotePatch(patch)
            }
            let didSave = logStore.saveRackFromRemote()
            pushSnapshot(message: didSave ? "rack_saved" : "rack_save_rejected")

        case .drillAttempt:
            guard let attempt = env.drillAttempt else { return }
            guard logStore.matchesActiveSession(env.sessionUUID) else {
                pushSnapshot(message: "stale_drill_attempt_ignored")
                return
            }
            let didSave = logStore.recordDrillAttemptFromRemote(attempt)
            if attempt.saveAndExit, let dataStore, didSave {
                Task {
                    await logStore.endSession(savingTo: dataStore)
                    await MainActor.run { self.pushSnapshot(message: "drill_session_ended") }
                }
            } else {
                pushSnapshot(message: didSave ? "drill_attempt_saved" : "drill_attempt_rejected")
            }

        case .drillDifficulty:
            guard let difficulty = env.drillDifficulty else { return }
            guard logStore.matchesActiveSession(env.sessionUUID) else {
                pushSnapshot(message: "stale_drill_difficulty_ignored")
                return
            }
            logStore.updateDrillDifficulty(levelRawValue: difficulty.difficulty, ballCount: difficulty.ballCount)
            pushSnapshot(message: "drill_difficulty_updated")

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
