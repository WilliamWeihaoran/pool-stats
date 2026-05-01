import Foundation

@MainActor
final class WatchSessionStore: ObservableObject {
    @Published private(set) var activeSnapshot: ActiveSessionSnapshot?
    @Published private(set) var cachedDrills: [WatchDrillTemplatePayload] = []

    private let key = "poolstats.watch.local.session.v1"
    private let drillsKey = "poolstats.watch.local.drills.v1"

    init() {
        restore()
        restoreDrills()
    }

    // Returns the generated sessionUUID so the caller can include it in the phone message.
    func startSession(game: String, opponent: String) -> String {
        let sessionUUID = UUID().uuidString
        let session = WatchSession(
            id: 0,
            sessionUUID: sessionUUID,
            label: "",
            opponent: opponent,
            game: game,
            type: "match",
            ts: Date(),
            racks: [],
            durationSeconds: nil,
            performanceRating: nil,
            drillID: nil,
            drillTitle: nil,
            drillKind: nil,
            drillDifficulty: nil,
            drillBallCount: nil,
            drillPrimarySkill: nil,
            drillPrimarySkills: nil,
            drillSubskills: nil,
            drillSecondarySkills: nil,
            drillTargetType: nil,
            drillTargetCount: nil
        )
        let now = Date()
        activeSnapshot = ActiveSessionSnapshot(session: session, rack: freshRack(index: 1), sessionStartedAt: now, rackStartedAt: now)
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
        let session = WatchSession(
            id: 0,
            sessionUUID: sessionUUID,
            label: drill.title,
            opponent: "",
            game: "8ball",
            type: "practice",
            ts: Date(),
            racks: [],
            durationSeconds: nil,
            performanceRating: nil,
            drillID: drill.id,
            drillTitle: drill.title,
            drillKind: nil,
            drillDifficulty: difficulty.level,
            drillBallCount: difficulty.ballCount,
            drillPrimarySkill: nil,
            drillPrimarySkills: nil,
            drillSubskills: nil,
            drillSecondarySkills: nil,
            drillTargetType: targetType,
            drillTargetCount: targetCount
        )
        let now = Date()
        activeSnapshot = ActiveSessionSnapshot(session: session, rack: freshRack(index: 1), sessionStartedAt: now, rackStartedAt: now)
        persist()
        return sessionUUID
    }

    func applyPatch(_ patch: WatchRackPatch) {
        guard var snap = activeSnapshot, var rack = snap.rack else { return }
        if let v = patch.result { rack.result = v }
        if let v = patch.breaker { rack.breaker = v }
        if let v = patch.breakBalls { rack.breakBalls = v }
        if let v = patch.breakFoul { rack.breakFoul = v }
        if let v = patch.layout { rack.layout = v }
        if let v = patch.outcome { rack.outcome = v }
        if let v = patch.fouls { rack.fouls = max(0, v) }
        if let v = patch.badSafety { rack.badSafety = max(0, v) }
        if let v = patch.badPosition { rack.badPosition = max(0, v) }
        if let v = patch.patternCount { rack.patternCount = max(0, v) }
        if let v = patch.missCount { rack.missCount = max(0, v) }
        if let v = patch.runoutFirst { rack.runoutFirst = v }
        if let v = patch.breakAndRun { rack.breakAndRun = v }
        snap.rack = rack
        activeSnapshot = snap
        persist()
    }

    func saveCurrentRack() {
        guard let snap = activeSnapshot, let rack = snap.rack else { return }
        var session = snap.session
        session.racks.append(rack)
        activeSnapshot = ActiveSessionSnapshot(session: session, rack: freshRack(index: rack.index + 1), sessionStartedAt: snap.sessionStartedAt, rackStartedAt: Date())
        persist()
    }

    func recordDrillAttempt(_ attempt: WatchDrillAttemptPayload) {
        guard let snap = activeSnapshot, snap.session.isDrillPractice else { return }
        var session = snap.session
        let rack = WatchRack(
            id: UUID().uuidString,
            rackUUID: UUID().uuidString,
            index: session.racks.count + 1,
            result: nil,
            breaker: "none",
            breakBalls: -1,
            breakFoul: false,
            layout: "none",
            outcome: nil,
            fouls: 0,
            badSafety: 0,
            badPosition: 0,
            patternCount: 0,
            missCount: 0,
            runoutFirst: false,
            breakAndRun: false,
            drillOutcome: attempt.outcome,
            drillTags: attempt.tags.isEmpty ? nil : attempt.tags,
            drillNotes: nil,
            drillBallsMade: attempt.ballsMade,
            drillTargetBallCount: attempt.targetBallCount,
            drillDifficulty: attempt.difficulty
        )
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

    func clear() {
        activeSnapshot = nil
        UserDefaults.standard.removeObject(forKey: key)
        WatchComplicationStateStore.clear()
    }

    func updateDrillCatalog(_ drills: [WatchDrillTemplatePayload]) {
        guard !drills.isEmpty else { return }
        cachedDrills = drills
        persistDrills()
    }

    // Phone snapshot is always authoritative — overwrite local state when it arrives.
    func applyRemote(_ remote: ActiveSessionSnapshot) {
        activeSnapshot = remote
        persist()
    }

    private func freshRack(index: Int) -> WatchRack {
        WatchRack(
            id: UUID().uuidString,
            rackUUID: UUID().uuidString,
            index: index,
            result: nil,
            breaker: "none",
            breakBalls: -1,
            breakFoul: false,
            layout: "open",
            outcome: nil,
            fouls: 0,
            badSafety: 0,
            badPosition: 0,
            patternCount: 0,
            missCount: 0,
            runoutFirst: false,
            breakAndRun: false,
            drillOutcome: nil,
            drillTags: nil,
            drillNotes: nil,
            drillBallsMade: nil,
            drillTargetBallCount: nil,
            drillDifficulty: nil
        )
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(activeSnapshot) else { return }
        UserDefaults.standard.set(data, forKey: key)
        WatchComplicationStateStore.save(active: activeSnapshot)
    }

    private func restore() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let snap = try? JSONDecoder().decode(ActiveSessionSnapshot.self, from: data) else { return }
        activeSnapshot = snap
        WatchComplicationStateStore.save(active: snap)
    }

    private func persistDrills() {
        guard let data = try? JSONEncoder().encode(cachedDrills) else { return }
        UserDefaults.standard.set(data, forKey: drillsKey)
    }

    private func restoreDrills() {
        guard let data = UserDefaults.standard.data(forKey: drillsKey),
              let drills = try? JSONDecoder().decode([WatchDrillTemplatePayload].self, from: data) else { return }
        cachedDrills = drills
    }
}
