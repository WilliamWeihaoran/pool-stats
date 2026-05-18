import Foundation
import WatchConnectivity

@MainActor
final class WatchConnectivityClient: NSObject, ObservableObject {
    @Published private(set) var snapshot: WatchSessionSnapshot?
    @Published private(set) var isReachable: Bool = false

    private let queue = WatchQueueStore()
    private weak var sessionStore: WatchSessionStore?

    override init() {
        super.init()
        activate()
    }

    func bind(to store: WatchSessionStore) {
        sessionStore = store
    }

    private func activate() {
        guard WCSession.isSupported() else { return }
        let s = WCSession.default
        s.delegate = self
        s.activate()
        // isReachable is set in activationDidCompleteWith — don't read it before activation finishes
    }

    private func nowMs() -> Int64 { Int64(Date().timeIntervalSince1970 * 1000) }

    func requestAttach() {
        send(WatchSyncEnvelope(action: .attachActiveSession, sentAtMs: nowMs()))
    }

    func startSession(game: String, opponent: String) {
        let sessionUUID = sessionStore?.startSession(game: game, opponent: opponent)
            ?? UUID().uuidString
        let initialRackUUID = sessionStore?.activeSnapshot?.rack?.rackUUID
        send(WatchSyncEnvelope(
            action: .startSession,
            sessionUUID: sessionUUID,
            start: WatchSessionStartPayload(
                game: game,
                type: "match",
                opponent: opponent,
                initialRackUUID: initialRackUUID,
                timestampMs: nowMs()
            ),
            sentAtMs: nowMs()
        ))
    }

    func startDrillPractice(drill: WatchDrillTemplatePayload, targetCount: Int) {
        let chosenDifficulty = drill.difficultyLevels.first(where: { $0.level == "standard" })
            ?? drill.difficultyLevels.first
            ?? WatchDrillTemplateDifficultyPayload(level: "standard", label: "Standard", ballCount: 5, constraint: "")
        let sessionUUID = sessionStore?.startDrillPractice(
            drill: drill,
            difficulty: chosenDifficulty,
            targetType: "successes",
            targetCount: targetCount
        ) ?? UUID().uuidString

        send(WatchSyncEnvelope(
            action: .startSession,
            sessionUUID: sessionUUID,
            start: WatchSessionStartPayload(
                game: "8ball",
                type: "practice",
                opponent: "",
                drillID: drill.id,
                targetType: "successes",
                targetCount: targetCount,
                drillDifficulty: chosenDifficulty.level,
                drillBallCount: chosenDifficulty.ballCount,
                initialRackUUID: sessionStore?.activeSnapshot?.rack?.rackUUID,
                timestampMs: nowMs()
            ),
            sentAtMs: nowMs()
        ))
    }

    func patch(_ patch: WatchRackPatch, sessionUUID: String?) {
        let rackUUID = sessionStore?.activeSnapshot?.rack?.rackUUID
        sessionStore?.applyPatch(patch)
        send(WatchSyncEnvelope(action: .rackPatch, sessionUUID: sessionUUID, rackUUID: rackUUID, patch: patch, sentAtMs: nowMs()))
    }

    func saveRack(sessionUUID: String?, patch: WatchRackPatch? = nil) {
        let rackUUID = sessionStore?.activeSnapshot?.rack?.rackUUID
        if let patch {
            sessionStore?.applyPatch(patch)
        }
        sessionStore?.saveCurrentRack()
        let nextRackUUID = sessionStore?.activeSnapshot?.rack?.rackUUID
        send(WatchSyncEnvelope(
            action: .saveRack,
            sessionUUID: sessionUUID,
            rackUUID: rackUUID,
            nextRackUUID: nextRackUUID,
            patch: patch,
            sentAtMs: nowMs()
        ))
    }

    func undoLastRack(sessionUUID: String?) {
        sessionStore?.undoLastRack()
        send(WatchSyncEnvelope(action: .undoLastRack, sessionUUID: sessionUUID, sentAtMs: nowMs()))
    }

    func recordDrillAttempt(_ attempt: WatchDrillAttemptPayload, sessionUUID: String?) {
        if !attempt.saveAndExit {
            sessionStore?.recordDrillAttempt(attempt)
        } else {
            sessionStore?.markLocallyClosed(sessionUUID: sessionUUID ?? sessionStore?.activeSnapshot?.session.sessionUUID)
        }
        send(WatchSyncEnvelope(action: .drillAttempt, sessionUUID: sessionUUID, drillAttempt: attempt, sentAtMs: nowMs()))
        if attempt.saveAndExit {
            sessionStore?.clear()
            clearSnapshotActive()
        }
    }

    func updateDrillDifficulty(_ payload: WatchDrillDifficultyPayload, sessionUUID: String?) {
        sessionStore?.updateDrillDifficulty(payload)
        send(WatchSyncEnvelope(action: .drillDifficulty, sessionUUID: sessionUUID, drillDifficulty: payload, sentAtMs: nowMs()))
    }

    func endSession(sessionUUID: String?, rating: Int) {
        sessionStore?.markLocallyClosed(sessionUUID: sessionUUID ?? sessionStore?.activeSnapshot?.session.sessionUUID)
        sessionStore?.clear(clearComplication: false)
        clearSnapshotActive()
        send(WatchSyncEnvelope(action: .endSessionWithRating, sessionUUID: sessionUUID, end: WatchEndSessionPayload(rating: rating), sentAtMs: nowMs()))
    }

    func discardSession(sessionUUID: String?) {
        sessionStore?.markLocallyClosed(sessionUUID: sessionUUID ?? sessionStore?.activeSnapshot?.session.sessionUUID)
        sessionStore?.clear()
        clearSnapshotActive()
        send(WatchSyncEnvelope(action: .discardSession, sessionUUID: sessionUUID, sentAtMs: nowMs()))
    }


    private func send(_ envelope: WatchSyncEnvelope) {
        let session = WCSession.default
        guard session.activationState == .activated else {
            queue.enqueue(envelope)
            return
        }
        guard let payload = WatchConnectivityCodec.payload(for: envelope) else { return }
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { [weak self] _ in
                Task { @MainActor in
                    self?.queue.enqueue(envelope)
                }
            }
        } else {
            queue.enqueue(envelope)
        }
    }

    private func flushQueueIfPossible() {
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable else { return }
        for env in queue.drain() {
            send(env)
        }
    }

    private func handleIncomingSnapshot(_ decoded: WatchSessionSnapshot) {
        if let drills = decoded.availableDrills {
            sessionStore?.updateDrillCatalog(drills)
        }
        // Phone is authoritative — adopt its active session if it has one.
        // If it has none with a matching clear marker, remove any local active state too.
        if let active = decoded.active {
            guard sessionStore?.shouldSuppressRemoteActive(active) != true else {
                snapshot = decoded.withoutActive(message: decoded.message)
                return
            }
            snapshot = decoded
            sessionStore?.applyRemote(active)
        } else if shouldClearLocalSession(for: decoded) {
            snapshot = decoded
            sessionStore?.clearClosedSessionMarkerForAcknowledgedClear(
                clearedSessionUUID: decoded.clearedSessionUUID,
                message: decoded.message
            )
            sessionStore?.clear(clearComplication: !shouldPreserveRecentlyEndedComplication(for: decoded))
        } else if sessionStore?.activeSnapshot == nil, shouldClearIdleComplication(for: decoded) {
            snapshot = decoded
            sessionStore?.clearClosedSessionMarkerForAcknowledgedClear(
                clearedSessionUUID: decoded.clearedSessionUUID,
                message: decoded.message
            )
            WatchComplicationStateStore.clear()
        } else {
            snapshot = decoded
            if decoded.active == nil {
                sessionStore?.clearClosedSessionMarkerForAcknowledgedClear(
                    clearedSessionUUID: decoded.clearedSessionUUID,
                    message: decoded.message
                )
            }
        }
    }

    private func clearSnapshotActive() {
        snapshot = snapshot?.withoutActive(message: nil)
    }

    private func shouldClearLocalSession(for snapshot: WatchSessionSnapshot) -> Bool {
        WatchSyncReconciler.shouldClearLocalSession(
            activeSessionUUID: sessionStore?.activeSnapshot?.session.sessionUUID,
            clearedSessionUUID: snapshot.clearedSessionUUID,
            message: snapshot.message
        )
    }

    private func shouldPreserveRecentlyEndedComplication(for snapshot: WatchSessionSnapshot) -> Bool {
        let complication = WatchComplicationStateStore.load()
        return WatchSyncReconciler.shouldPreserveRecentlyEndedComplication(
            activeSessionUUID: sessionStore?.activeSnapshot?.session.sessionUUID,
            message: snapshot.message,
            clearedSessionUUID: snapshot.clearedSessionUUID,
            complicationSessionUUID: complication.sessionUUID,
            recentlyEndedAt: complication.recentlyEndedAt
        )
    }

    private func shouldClearIdleComplication(for snapshot: WatchSessionSnapshot) -> Bool {
        let complication = WatchComplicationStateStore.load()
        return WatchSyncReconciler.shouldClearIdleComplication(
            hasActiveSession: complication.hasActiveSession,
            recentlyEndedAt: complication.recentlyEndedAt,
            complicationSessionUUID: complication.sessionUUID,
            snapshotClearedSessionUUID: snapshot.clearedSessionUUID
        )
    }
}

extension WatchConnectivityClient: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            self.flushQueueIfPossible()
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            self.flushQueueIfPossible()
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            guard let decoded = WatchConnectivityCodec.snapshot(from: message) else { return }
            self.handleIncomingSnapshot(decoded)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            guard let decoded = WatchConnectivityCodec.snapshot(from: applicationContext) else { return }
            self.handleIncomingSnapshot(decoded)
        }
    }
}
