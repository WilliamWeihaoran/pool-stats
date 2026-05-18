import Foundation
import Combine
import WatchConnectivity

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
    var initialRackUUID: String?
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
    var nextRackUUID: String?
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
        if self.dataStore === dataStore,
           self.logStore === logStore,
           self.opponentStore === opponentStore,
           !cancellables.isEmpty {
            return
        }

        cancellables.removeAll()
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

    private func pushSnapshot(message: String?) {
        guard WCSession.isSupported() else { return }
        let snapshot = makeSnapshot(message: message)
        guard let payload = WatchPhoneSnapshotTransport.payload(for: snapshot) else { return }
        WatchPhoneSnapshotTransport.sendSnapshot(payload: payload, using: WCSession.default)
    }

    private func acceptsSessionScopedEnvelope(_ env: WatchSyncEnvelope) -> Bool {
        WatchSyncReconciler.acceptsSessionScopedEnvelope(
            currentSessionUUID: logStore?.currentSession?.sessionUUID,
            envelopeSessionUUID: env.sessionUUID
        )
    }

    private func acceptsRackScopedEnvelope(_ env: WatchSyncEnvelope) -> Bool {
        WatchSyncReconciler.acceptsRackScopedEnvelope(
            currentSessionUUID: logStore?.currentSession?.sessionUUID,
            currentRackUUID: logStore?.currentRack?.rackUUID,
            envelopeSessionUUID: env.sessionUUID,
            envelopeRackUUID: env.rackUUID
        )
    }

    private func handle(_ env: WatchSyncEnvelope) {
        guard let logStore else { return }
        switch env.action {
        case .attachActiveSession:
            pushSnapshot(message: "attached")

        case .startSession:
            guard let start = env.start else { return }
            let sessionUUID = WatchSyncReconciler.normalizedIdentifier(env.sessionUUID)
            // Dedup: if this session is already active (queue replay), don't restart it.
            if let sessionUUID, logStore.matchesActiveSession(sessionUUID) {
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
                    sessionUUID: sessionUUID
                )
                logStore.setCurrentRackUUID(start.initialRackUUID)
                pushSnapshot(message: "drill_session_started")
            } else {
                let date = start.timestampMs.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) } ?? Date()
                logStore.startSession(
                    game: start.game,
                    label: "",
                    opponent: start.opponent,
                    date: date,
                    sessionUUID: sessionUUID
                )
                logStore.setCurrentRackUUID(start.initialRackUUID)
                pushSnapshot(message: "session_started")
            }

        case .rackPatch:
            guard let patch = env.patch else { return }
            guard acceptsRackScopedEnvelope(env) else {
                pushSnapshot(message: "stale_patch_ignored")
                return
            }
            logStore.applyRemotePatch(patch)
            pushSnapshot(message: "rack_patched")

        case .saveRack:
            guard acceptsRackScopedEnvelope(env) else {
                pushSnapshot(message: "stale_save_ignored")
                return
            }
            if let patch = env.patch {
                logStore.applyRemotePatch(patch)
            }
            let didSave = logStore.saveRackFromRemote()
            if didSave {
                logStore.setCurrentRackUUID(env.nextRackUUID)
            }
            pushSnapshot(message: didSave ? "rack_saved" : "rack_save_rejected")

        case .drillAttempt:
            guard let attempt = env.drillAttempt else { return }
            guard acceptsSessionScopedEnvelope(env) else {
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
            guard acceptsSessionScopedEnvelope(env) else {
                pushSnapshot(message: "stale_drill_difficulty_ignored")
                return
            }
            logStore.updateDrillDifficulty(levelRawValue: difficulty.difficulty, ballCount: difficulty.ballCount)
            pushSnapshot(message: "drill_difficulty_updated")

        case .undoLastRack:
            guard acceptsSessionScopedEnvelope(env) else {
                pushSnapshot(message: "stale_undo_ignored")
                return
            }
            _ = logStore.undoLastRackFromRemote()
            pushSnapshot(message: "rack_undone")

        case .discardSession:
            guard acceptsSessionScopedEnvelope(env) else {
                pushSnapshot(message: "stale_discard_ignored")
                return
            }
            logStore.discardSession()
            pushSnapshot(message: "session_discarded")

        case .endSessionWithRating:
            guard let end = env.end, let dataStore else { return }
            guard acceptsSessionScopedEnvelope(env) else {
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
            guard let env = WatchPhoneSnapshotTransport.envelope(from: message) else { return }
            self.handle(env)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            if WatchPhoneSnapshotTransport.isSnapshotMessage(applicationContext) {
                return
            }
            guard let env = WatchPhoneSnapshotTransport.envelope(from: applicationContext) else { return }
            self.handle(env)
        }
    }
}
