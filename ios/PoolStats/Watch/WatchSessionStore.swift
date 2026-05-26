import Foundation

@MainActor
final class WatchSessionStore: ObservableObject {
    @Published private(set) var activeSnapshot: ActiveSessionSnapshot?
    @Published private(set) var cachedDrills: [WatchDrillTemplatePayload] = []

    private var closedSessionMarker: WatchClosedSessionMarker?

    init() {
        activeSnapshot = WatchSessionPersistence.restoreActive()
        cachedDrills = WatchSessionPersistence.restoreDrills()
        closedSessionMarker = WatchSessionPersistence.restoreClosedSessionMarker()
    }

    // Returns the generated sessionUUID so the caller can include it in the phone message.
    func startSession(game: String, opponent: String) -> String {
        let sessionUUID = UUID().uuidString
        let now = Date()
        clearStoredClosedSessionMarker()
        let session = WatchSessionFactory.matchSession(
            game: game,
            opponent: opponent,
            sessionUUID: sessionUUID,
            date: now
        )
        activeSnapshot = ActiveSessionSnapshot(
            session: session,
            rack: WatchSessionFactory.freshRack(index: 1),
            sessionStartedAt: now,
            rackStartedAt: now
        )
        persist()
        return sessionUUID
    }

    // Returns generated sessionUUID so caller can include it in phone message.
    func startDrillPractice(
        drill: WatchDrillTemplatePayload,
        difficulty: WatchDrillTemplateDifficultyPayload,
        targetType: String = "successes",
        targetCount: Int
    ) -> String {
        let sessionUUID = UUID().uuidString
        let now = Date()
        clearStoredClosedSessionMarker()
        let session = WatchSessionFactory.drillPracticeSession(
            drill: drill,
            difficulty: difficulty,
            targetType: targetType,
            targetCount: targetCount,
            sessionUUID: sessionUUID,
            date: now
        )
        activeSnapshot = ActiveSessionSnapshot(
            session: session,
            rack: WatchSessionFactory.freshRack(index: 1),
            sessionStartedAt: now,
            rackStartedAt: now
        )
        persist()
        return sessionUUID
    }

    func applyPatch(_ patch: WatchRackPatch) {
        guard var snap = activeSnapshot, var rack = snap.rack else { return }
        rack.apply(patch)
        snap.rack = rack
        activeSnapshot = snap
        persist()
    }

    func saveCurrentRack() {
        guard let snap = activeSnapshot, let rack = snap.rack else { return }
        var session = snap.session
        session.racks.append(rack)
        activeSnapshot = ActiveSessionSnapshot(
            session: session,
            rack: WatchSessionFactory.freshRack(index: rack.index + 1),
            sessionStartedAt: snap.sessionStartedAt,
            rackStartedAt: Date()
        )
        persist()
    }

    func recordDrillAttempt(_ attempt: WatchDrillAttemptPayload) {
        guard let snap = activeSnapshot, snap.session.isDrillPractice else { return }
        var session = snap.session
        let rack = WatchSessionFactory.drillAttemptRack(index: session.racks.count + 1, attempt: attempt)
        session.racks.append(rack)
        activeSnapshot = ActiveSessionSnapshot(session: session, rack: nil, sessionStartedAt: snap.sessionStartedAt, rackStartedAt: snap.rackStartedAt)
        persist()
    }

    func updateDrillDifficulty(_ payload: WatchDrillDifficultyPayload) {
        guard let snap = activeSnapshot, snap.session.isDrillPractice else { return }
        var session = snap.session
        session.drillDifficulty = payload.difficulty
        session.drillBallCount = payload.ballCount
        activeSnapshot = ActiveSessionSnapshot(session: session, rack: snap.rack, sessionStartedAt: snap.sessionStartedAt, rackStartedAt: snap.rackStartedAt)
        persist()
    }

    func undoLastRack() {
        guard let snap = activeSnapshot, !snap.session.racks.isEmpty else { return }
        var session = snap.session
        let restored = session.racks.removeLast()
        activeSnapshot = ActiveSessionSnapshot(session: session, rack: restored, sessionStartedAt: snap.sessionStartedAt, rackStartedAt: snap.rackStartedAt)
        persist()
    }

    func clear(clearComplication: Bool = true) {
        activeSnapshot = nil
        WatchSessionPersistence.clearActive(clearComplication: clearComplication)
    }

    func markLocallyClosed(sessionUUID: String?) {
        closedSessionMarker = WatchSessionPersistence.marker(sessionUUID: sessionUUID)
        WatchSessionPersistence.saveClosedSessionMarker(closedSessionMarker)
    }

    func shouldSuppressRemoteActive(_ remote: ActiveSessionSnapshot, now: Date = Date()) -> Bool {
        WatchSyncReconciler.shouldSuppressActiveSnapshotAfterLocalClose(
            remoteSessionUUID: remote.session.sessionUUID,
            locallyClosedSessionUUID: closedSessionMarker?.sessionUUID,
            locallyClosedAt: closedSessionMarker?.closedAt,
            now: now
        )
    }

    func clearClosedSessionMarker(matching sessionUUID: String?) {
        guard let closedSessionMarker else { return }
        guard let sessionUUID = WatchSyncReconciler.normalizedIdentifier(sessionUUID) else { return }
        guard sessionUUID == closedSessionMarker.sessionUUID else { return }
        clearStoredClosedSessionMarker()
    }

    func clearClosedSessionMarkerForAcknowledgedClear(clearedSessionUUID: String?, message: String?) {
        if let clearedSessionUUID = WatchSyncReconciler.normalizedIdentifier(clearedSessionUUID) {
            clearClosedSessionMarker(matching: clearedSessionUUID)
        } else if WatchSyncReconciler.isSessionClearMessage(message) {
            clearStoredClosedSessionMarker()
        }
    }

    func updateDrillCatalog(_ drills: [WatchDrillTemplatePayload]) {
        guard !drills.isEmpty else { return }
        cachedDrills = drills
        WatchSessionPersistence.saveDrills(drills)
    }

    // Phone snapshots are authoritative unless they echo a session this watch just closed.
    func applyRemote(_ remote: ActiveSessionSnapshot) {
        if let marker = closedSessionMarker,
           marker.sessionUUID != WatchSyncReconciler.normalizedIdentifier(remote.session.sessionUUID) || !shouldSuppressRemoteActive(remote) {
            clearStoredClosedSessionMarker()
        }
        activeSnapshot = remote
        persist()
    }

    private func persist() {
        WatchSessionPersistence.saveActive(activeSnapshot)
    }

    private func clearStoredClosedSessionMarker() {
        closedSessionMarker = nil
        WatchSessionPersistence.clearClosedSessionMarker()
    }
}
