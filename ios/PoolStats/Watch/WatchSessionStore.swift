import Foundation

@MainActor
final class WatchSessionStore: ObservableObject {
    @Published private(set) var activeSnapshot: ActiveSessionSnapshot?

    private let key = "poolstats.watch.local.session.v1"

    init() { restore() }

    // Returns the generated sessionUUID so the caller can include it in the phone message.
    func startSession(game: String, type: String, opponent: String) -> String {
        let sessionUUID = UUID().uuidString
        let session = WatchSession(
            id: 0,
            sessionUUID: sessionUUID,
            label: "",
            opponent: opponent,
            game: game,
            type: type,
            ts: Date(),
            racks: [],
            durationSeconds: nil,
            performanceRating: nil
        )
        activeSnapshot = ActiveSessionSnapshot(session: session, rack: freshRack(index: 1))
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
        if let v = patch.missCount { rack.missCount = max(0, v) }
        if let v = patch.runoutFirst { rack.runoutFirst = v }
        if let v = patch.breakAndRun { rack.breakAndRun = v }
        snap.rack = rack
        activeSnapshot = snap
        persist()
    }

    @discardableResult
    func saveCurrentRack() -> WatchSession? {
        guard let snap = activeSnapshot, let rack = snap.rack else { return nil }
        var session = snap.session
        session.racks.append(rack)
        activeSnapshot = ActiveSessionSnapshot(session: session, rack: freshRack(index: rack.index + 1))
        persist()
        return session
    }

    func undoLastRack() {
        guard let snap = activeSnapshot, !snap.session.racks.isEmpty else { return }
        var session = snap.session
        let restored = session.racks.removeLast()
        activeSnapshot = ActiveSessionSnapshot(session: session, rack: restored)
        persist()
    }

    func clear() {
        activeSnapshot = nil
        UserDefaults.standard.removeObject(forKey: key)
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
            missCount: 0,
            runoutFirst: false,
            breakAndRun: false
        )
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(activeSnapshot) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func restore() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let snap = try? JSONDecoder().decode(ActiveSessionSnapshot.self, from: data) else { return }
        activeSnapshot = snap
    }
}
