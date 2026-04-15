import Foundation

@MainActor
final class DataStore: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var currentSession: Session?
    @Published var currentRack: Rack?
    @Published var lastEndedSession: Session?
    @Published var isLoading: Bool = false
    @Published var lastError: String?
    @Published var sessionStart: Date?
    @Published var rackStart: Date?

    private let service = SessionService()
    private let seedFlagKey = "didSeedSampleData"
    private let localURL: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("PoolStats", isDirectory: true)
        localURL = dir.appendingPathComponent("sessions.json")
        loadLocal()
        Task { await refresh() }
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        let localSnapshot = sessions
        do {
            let fetched = try await service.fetchAllSessions()
            if fetched.isEmpty && !localSnapshot.isEmpty {
                sessions = localSnapshot
                try? await service.replaceAllSessions(existingIDs: [], with: localSnapshot)
            } else {
                sessions = fetched
            }
            saveLocal()
            lastError = nil
            await seedIfNeeded()
        } catch {
            lastError = error.localizedDescription
            if sessions.isEmpty {
                await seedFallback()
            }
        }
    }

    func startSession(game: String, type: String, label: String, date: Date) {
        let finalLabel = type == "practice" ? "Practice" : label
        let cal = Calendar.current
        let sessionDate = cal.startOfDay(for: date)
        currentSession = Session(label: finalLabel, game: game, type: type, ts: sessionDate)
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
            if rack.breaker == "open" {
                rack.layout = "open"
            }
        }
        rack.breakAndRun = rack.runoutFirst && rack.breaker == "me" && rack.breakBalls >= 1
        currentRack = rack
    }

    func saveRack() -> Bool {
        guard var session = currentSession, var rack = currentRack else { return false }
        let ok = session.isPractice ? rack.outcome != nil : (rack.result != nil && rack.outcome != nil)
        guard ok else { return false }
        if session.isPractice { rack.result = nil }
        session.racks.append(rack)
        currentSession = session
        resetRack()
        return true
    }

    func endSession() async {
        guard var session = currentSession else { return }
        if session.racks.isEmpty {
            currentSession = nil
            currentRack = nil
            sessionStart = nil
            rackStart = nil
            return
        }
        if let start = sessionStart {
            session.durationSeconds = max(0, Int(Date().timeIntervalSince(start)))
        }
        do {
            try await service.saveSession(session)
            sessions.append(session)
            saveLocal()
            currentSession = nil
            currentRack = nil
            sessionStart = nil
            rackStart = nil
            lastEndedSession = session
            lastError = nil
        } catch {
            sessions.append(session)
            saveLocal()
            currentSession = nil
            currentRack = nil
            sessionStart = nil
            rackStart = nil
            lastEndedSession = session
            lastError = "Saved locally. iCloud sync failed."
        }
    }

    func updateSessionLabel(sessionID: Int64, label: String) async {
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
            if lastEndedSession?.id == sessionID {
                lastEndedSession = sess
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            if let idx = sessions.firstIndex(where: { $0.id == sessionID }) {
                sessions[idx] = sess
                saveLocal()
            }
        }
    }

    func deleteSessions(ids: [Int64]) async {
        do {
            try await service.deleteSessions(ids)
            sessions.removeAll { ids.contains($0.id) }
            saveLocal()
            if let last = lastEndedSession, ids.contains(last.id) {
                lastEndedSession = nil
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func exportJSON() -> Data? {
        JSONTransfer.exportSessions(sessions)
    }

    func importJSON(_ data: Data) async {
        do {
            let newSessions = try JSONTransfer.importSessions(data)
            try await replaceAllSessions(newSessions)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func restoreSampleData() async {
        let sample = SampleData.makeSessions()
        do {
            let existingIDs = sessions.map { $0.id }
            try await service.replaceAllSessions(existingIDs: existingIDs, with: sample)
            sessions = sample
            saveLocal()
            UserDefaults.standard.set(true, forKey: seedFlagKey)
            lastError = nil
        } catch {
            sessions = sample
            saveLocal()
            UserDefaults.standard.set(true, forKey: seedFlagKey)
            lastError = error.localizedDescription
        }
    }

    private func replaceAllSessions(_ newSessions: [Session]) async throws {
        let existingIDs = sessions.map { $0.id }
        try await service.replaceAllSessions(existingIDs: existingIDs, with: newSessions)
        sessions = newSessions
        saveLocal()
        lastEndedSession = nil
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
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func seedFallback() async {
        guard sessions.isEmpty else { return }
        if UserDefaults.standard.bool(forKey: seedFlagKey) { return }
        sessions = SampleData.makeSessions()
        saveLocal()
        UserDefaults.standard.set(true, forKey: seedFlagKey)
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
}
