import Foundation

@MainActor
final class SessionLogStore: ObservableObject {
    @Published var currentSession: Session?
    @Published var currentRack: Rack?
    @Published var lastEndedSession: Session?
    @Published var sessionStart: Date?
    @Published var rackStart: Date?

    func startSession(game: String, type: String, label: String, opponent: String, date: Date) {
        let finalLabel = type == "practice" ? "Practice" : label
        let cal = Calendar.current
        let sessionDate = cal.startOfDay(for: date)
        currentSession = Session(label: finalLabel, opponent: opponent, game: game, type: type, ts: sessionDate)
        sessionStart = cal.isDateInToday(date) ? Date() : nil
        resetRack()
    }

    func resetRack() {
        guard let session = currentSession else { return }
        let nextIndex = session.racks.count + 1
        currentRack = Rack(index: nextIndex)
        rackStart = sessionStart == nil ? nil : Date()
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

    func discardSession() {
        clearState()
    }

    private func clearState() {
        currentSession = nil
        currentRack = nil
        sessionStart = nil
        rackStart = nil
    }
}
