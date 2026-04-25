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

    func startSession(game: String, type: String, opponent: String) {
        let normalizedType = "match"
        let sessionUUID = sessionStore?.startSession(game: game, type: normalizedType, opponent: opponent)
            ?? UUID().uuidString
        send(WatchSyncEnvelope(
            action: .startSession,
            sessionUUID: sessionUUID,
            start: WatchSessionStartPayload(game: game, type: normalizedType, opponent: opponent, timestampMs: nowMs()),
            sentAtMs: nowMs()
        ))
    }

    func patch(_ patch: WatchRackPatch, sessionUUID: String?) {
        sessionStore?.applyPatch(patch)
        send(WatchSyncEnvelope(action: .rackPatch, sessionUUID: sessionUUID, patch: patch, sentAtMs: nowMs()))
    }

    func saveRack(sessionUUID: String?) {
        sessionStore?.saveCurrentRack()
        send(WatchSyncEnvelope(action: .saveRack, sessionUUID: sessionUUID, sentAtMs: nowMs()))
    }

    func undoLastRack(sessionUUID: String?) {
        sessionStore?.undoLastRack()
        send(WatchSyncEnvelope(action: .undoLastRack, sessionUUID: sessionUUID, sentAtMs: nowMs()))
    }

    func recordDrillAttempt(_ attempt: WatchDrillAttemptPayload, sessionUUID: String?) {
        if !attempt.saveAndExit {
            sessionStore?.recordDrillAttempt(attempt)
        }
        send(WatchSyncEnvelope(action: .drillAttempt, sessionUUID: sessionUUID, drillAttempt: attempt, sentAtMs: nowMs()))
        if attempt.saveAndExit {
            sessionStore?.clear()
            snapshot = snapshot.map { WatchSessionSnapshot(active: nil, availableOpponents: $0.availableOpponents, acknowledgedAtMs: $0.acknowledgedAtMs, message: nil) }
        }
    }

    func updateDrillDifficulty(_ payload: WatchDrillDifficultyPayload, sessionUUID: String?) {
        sessionStore?.updateDrillDifficulty(payload)
        send(WatchSyncEnvelope(action: .drillDifficulty, sessionUUID: sessionUUID, drillDifficulty: payload, sentAtMs: nowMs()))
    }

    func endSession(sessionUUID: String?, rating: Int) {
        sessionStore?.clear()
        snapshot = snapshot.map { WatchSessionSnapshot(active: nil, availableOpponents: $0.availableOpponents, acknowledgedAtMs: $0.acknowledgedAtMs, message: nil) }
        send(WatchSyncEnvelope(action: .endSessionWithRating, sessionUUID: sessionUUID, end: WatchEndSessionPayload(rating: rating), sentAtMs: nowMs()))
    }

    func discardSession(sessionUUID: String?) {
        sessionStore?.clear()
        snapshot = snapshot.map { WatchSessionSnapshot(active: nil, availableOpponents: $0.availableOpponents, acknowledgedAtMs: $0.acknowledgedAtMs, message: nil) }
        send(WatchSyncEnvelope(action: .discardSession, sessionUUID: sessionUUID, sentAtMs: nowMs()))
    }


    private func send(_ envelope: WatchSyncEnvelope) {
        let session = WCSession.default
        guard session.activationState == .activated else {
            queue.enqueue(envelope)
            return
        }
        guard let data = try? JSONEncoder().encode(envelope),
              let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
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
            // Strip rackUUID so the phone accepts queued patches regardless of local UUID mismatch.
            // matchesActiveRack(nil) always returns true on the phone side.
            var stripped = env
            stripped.rackUUID = nil
            send(stripped)
        }
    }

    private func handleIncomingSnapshot(_ decoded: WatchSessionSnapshot) {
        snapshot = decoded
        // Phone is authoritative — adopt its active session if it has one.
        // If it has none, keep local state; our queued messages may not have arrived yet.
        if let active = decoded.active {
            sessionStore?.applyRemote(active)
        } else if sessionStore?.activeSnapshot == nil {
            WatchComplicationStateStore.clear()
        }
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
            guard let action = message["action"] as? String,
                  action == WatchSyncAction.sessionSnapshot.rawValue,
                  let snapshotObj = message["snapshot"],
                  let data = try? JSONSerialization.data(withJSONObject: snapshotObj),
                  let decoded = try? JSONDecoder().decode(WatchSessionSnapshot.self, from: data) else { return }
            self.handleIncomingSnapshot(decoded)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            guard let action = applicationContext["action"] as? String,
                  action == WatchSyncAction.sessionSnapshot.rawValue,
                  let snapshotObj = applicationContext["snapshot"],
                  let data = try? JSONSerialization.data(withJSONObject: snapshotObj),
                  let decoded = try? JSONDecoder().decode(WatchSessionSnapshot.self, from: data) else { return }
            self.handleIncomingSnapshot(decoded)
        }
    }
}
