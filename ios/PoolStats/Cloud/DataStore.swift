import Foundation

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

    private let service = SessionService()
    private let seedFlagKey = "didSeedSampleData"
    private let localURL: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("PoolStats", isDirectory: true)
        localURL = dir.appendingPathComponent("sessions.json")
        loadLocal()
        syncStatus = sessions.isEmpty ? .loading : .localOnly("Loaded local cache")
        Task { await refresh() }
    }

    func refresh() async {
        isLoading = true
        syncStatus = .syncing
        defer { isLoading = false }
        let localSnapshot = sessions
        do {
            let fetched = try await service.fetchAllSessions()
            if fetched.isEmpty && !localSnapshot.isEmpty {
                sessions = localSnapshot
                do {
                    try await service.replaceAllSessions(existingIDs: [], with: localSnapshot)
                    syncStatus = .synced
                } catch {
                    syncStatus = .localOnly("Saved locally. iCloud sync failed.")
                }
            } else {
                sessions = fetched
                syncStatus = .synced
            }
            saveLocal()
            lastError = nil
            await seedIfNeeded()
        } catch {
            lastError = error.localizedDescription
            if sessions.isEmpty {
                await seedFallback()
                syncStatus = .localOnly("Using local sample data")
            } else {
                syncStatus = .localOnly("Offline: using local cache")
            }
        }
    }

    func saveSession(_ session: Session) async {
        syncStatus = .syncing
        do {
            try await service.saveSession(session)
            sessions.append(session)
            saveLocal()
            lastError = nil
            syncStatus = .synced
        } catch {
            sessions.append(session)
            saveLocal()
            lastError = "Saved locally. iCloud sync failed."
            syncStatus = .localOnly("Saved locally. iCloud sync failed.")
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
            syncStatus = .synced
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            syncStatus = .localOnly("Updated locally. iCloud sync failed.")
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
            lastError = nil
            syncStatus = .synced
        } catch {
            lastError = error.localizedDescription
            syncStatus = .localOnly("Delete saved locally. iCloud sync failed.")
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
            syncStatus = .synced
        } catch {
            lastError = error.localizedDescription
            syncStatus = .error("Import failed")
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
            syncStatus = .synced
        } catch {
            sessions = sample
            saveLocal()
            UserDefaults.standard.set(true, forKey: seedFlagKey)
            lastError = error.localizedDescription
            syncStatus = .localOnly("Sample data saved locally only")
        }
    }

    private func replaceAllSessions(_ newSessions: [Session]) async throws {
        let existingIDs = sessions.map { $0.id }
        try await service.replaceAllSessions(existingIDs: existingIDs, with: newSessions)
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
}

// MARK: - Session Log Store

@MainActor
final class SessionLogStore: ObservableObject {
    @Published var currentSession: Session?
    @Published var currentRack: Rack?
    @Published var lastEndedSession: Session?
    @Published var sessionStart: Date?
    @Published var rackStart: Date?

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
