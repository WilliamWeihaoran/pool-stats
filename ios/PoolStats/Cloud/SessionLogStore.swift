import Foundation

@MainActor
final class SessionLogStore: ObservableObject {
    @Published var currentSession: Session?
    @Published var currentRack: Rack?
    @Published var lastEndedSession: Session?
    @Published var sessionStart: Date?
    @Published var rackStart: Date?
    @Published var externalUpdateNotice: String?

    func startSession(
        game: String,
        type: String,
        label: String,
        opponent: String,
        date: Date,
        sessionUUID: String? = nil
    ) {
        let finalLabel = type == "practice" ? "Practice" : label
        let cal = Calendar.current
        let isToday = cal.isDateInToday(date)
        let sessionDate = isToday ? Date() : cal.startOfDay(for: date)
        currentSession = Session(
            sessionUUID: sessionUUID ?? UUID().uuidString,
            label: finalLabel,
            opponent: opponent,
            game: game,
            type: type,
            ts: sessionDate
        )
        sessionStart = isToday ? sessionDate : nil
        resetRack()
    }

    func resetRack() {
        guard let session = currentSession else { return }
        let nextIndex = session.racks.count + 1
        currentRack = Rack(index: nextIndex)
        rackStart = sessionStart == nil ? nil : Date()
    }

    func attachActiveSession(_ session: Session, inProgressRack: Rack?) {
        currentSession = session
        currentRack = inProgressRack ?? Rack(index: session.racks.count + 1)
        if sessionStart == nil, Calendar.current.isDateInToday(session.ts) {
            sessionStart = Date()
        }
        if rackStart == nil {
            rackStart = Date()
        }
    }

    func matchesActiveSession(_ sessionUUID: String?) -> Bool {
        guard let sessionUUID else { return true }
        return currentSession?.sessionUUID == sessionUUID
    }

    func matchesActiveRack(_ rackUUID: String?) -> Bool {
        guard let rackUUID else { return true }
        return currentRack?.rackUUID == rackUUID
    }

    func updateRack(_ update: (inout Rack) -> Void) {
        guard var rack = currentRack else { return }
        update(&rack)
        if rack.breaker == "open" || rack.breaker == "none" {
            rack.breakBalls = -1
            rack.breakFoul = false
            if rack.breaker == "open" { rack.layout = "open" }
        }
        rack.breakAndRun = rack.runoutFirst && rack.breaker == "me" && rack.breakBalls >= 1
        currentRack = rack
    }

    func applyRemotePatch(_ patch: WatchRackPatch) {
        updateRack { rack in
            if let result = patch.result { rack.result = result }
            if let breaker = patch.breaker { rack.breaker = breaker }
            if let breakBalls = patch.breakBalls { rack.breakBalls = breakBalls }
            if let breakFoul = patch.breakFoul { rack.breakFoul = breakFoul }
            if let layout = patch.layout { rack.layout = layout }
            if let outcome = patch.outcome { rack.outcome = outcome }
            if let fouls = patch.fouls { rack.fouls = max(0, fouls) }
            if let badSafety = patch.badSafety { rack.badSafety = max(0, badSafety) }
            if let badPosition = patch.badPosition { rack.badPosition = max(0, badPosition) }
            if let missCount = patch.missCount { rack.missCount = max(0, missCount) }
            if let runoutFirst = patch.runoutFirst { rack.runoutFirst = runoutFirst }
            if let breakAndRun = patch.breakAndRun { rack.breakAndRun = breakAndRun }
        }
        showExternalNotice("Updated from watch")
    }

    @discardableResult
    func saveRackFromRemote() -> Bool {
        let ok = saveRack()
        if ok { showExternalNotice("Rack saved on watch") }
        return ok
    }

    func saveRack() -> Bool {
        guard var session = currentSession, var rack = currentRack else { return false }
        let breakOK = rack.breaker != "none" && rack.breakBalls >= 0
        let convertedOK = session.isPractice ? true : rack.outcome != nil
        let resultOK = session.isPractice ? true : rack.result != nil
        guard breakOK && convertedOK && resultOK else { return false }
        if session.isPractice { rack.result = nil }
        session.racks.append(rack)
        currentSession = session
        resetRack()
        return true
    }

    @discardableResult
    func undoLastRack() -> Bool {
        guard var session = currentSession, !session.racks.isEmpty else { return false }
        session.racks.removeLast()
        currentSession = session
        resetRack()
        showExternalNotice("Undo from watch")
        return true
    }

    @discardableResult
    func removeMostRecentRack(result: String) -> Bool {
        guard var session = currentSession,
              let idx = session.racks.lastIndex(where: { $0.result == result }) else { return false }
        session.racks.remove(at: idx)
        session.racks = session.racks.enumerated().map { offset, rack in
            var updated = rack
            updated.index = offset + 1
            return updated
        }
        currentSession = session
        resetRack()
        return true
    }

    @discardableResult
    func undoLastRackFromRemote() -> Bool {
        undoLastRack()
    }

    func endSession(savingTo store: DataStore) async {
        guard var session = currentSession, !session.racks.isEmpty else {
            discardSession()
            return
        }
        if let start = sessionStart {
            session.durationSeconds = max(0, Int(Date().timeIntervalSince(start)))
        }
        await store.saveSession(session)
        lastEndedSession = session
        clearState()
    }

    func endSessionFromRemote(rating: Int, savingTo store: DataStore) async {
        guard var currentSession else { return }
        currentSession.performanceRating = max(1, min(10, rating))
        self.currentSession = currentSession
        await endSession(savingTo: store)
        showExternalNotice("Session ended on watch")
    }

    func discardSession() {
        clearState()
    }

    private func clearState() {
        currentSession = nil
        currentRack = nil
        sessionStart = nil
        rackStart = nil
        externalUpdateNotice = nil
    }

    var activeSnapshot: ActiveSessionSnapshot? {
        guard let currentSession else { return nil }
        return ActiveSessionSnapshot(session: currentSession, rack: currentRack)
    }

    private func showExternalNotice(_ text: String) {
        externalUpdateNotice = text
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            if self?.externalUpdateNotice == text {
                self?.externalUpdateNotice = nil
            }
        }
    }
}

struct WatchRackPatch: Codable, Hashable {
    var result: String?
    var breaker: String?
    var breakBalls: Int?
    var breakFoul: Bool?
    var layout: String?
    var outcome: String?
    var fouls: Int?
    var badSafety: Int?
    var badPosition: Int?
    var missCount: Int?
    var runoutFirst: Bool?
    var breakAndRun: Bool?
}

struct ActiveSessionSnapshot: Codable, Hashable {
    var session: Session
    var rack: Rack?
}
