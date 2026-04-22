import Foundation
import AuthenticationServices
import Security

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
    @Published var lastSyncAttemptAt: Date?
    @Published var lastSyncSuccessAt: Date?
    @Published var lastSyncFailureReason: String?

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
        markSyncAttempt()
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
                    markSyncSuccess()
                } catch {
                    syncStatus = .localOnly("Saved locally. iCloud sync failed.")
                    markSyncFailure("Saved locally. iCloud sync failed.")
                }
            } else {
                sessions = fetched
                syncStatus = .synced
                markSyncSuccess()
            }
            saveLocal()
            lastError = nil
            await seedIfNeeded()
        } catch {
            lastError = error.localizedDescription
            markSyncFailure(error.localizedDescription)
            if sessions.isEmpty {
                await seedFallback()
                syncStatus = .localOnly("Using local sample data")
            } else {
                syncStatus = .localOnly("Offline: using local cache")
            }
        }
    }

    func saveSession(_ session: Session) async {
        markSyncAttempt()
        syncStatus = .syncing
        do {
            try await service.saveSession(session)
            sessions.append(session)
            saveLocal()
            lastError = nil
            syncStatus = .synced
            markSyncSuccess()
        } catch {
            sessions.append(session)
            saveLocal()
            lastError = "Saved locally. iCloud sync failed."
            syncStatus = .localOnly("Saved locally. iCloud sync failed.")
            markSyncFailure("Saved locally. iCloud sync failed.")
        }
    }

    func updateSessionLabel(sessionID: Int64, label: String) async {
        markSyncAttempt()
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
            markSyncSuccess()
        } catch {
            lastError = error.localizedDescription
            syncStatus = .localOnly("Updated locally. iCloud sync failed.")
            markSyncFailure("Updated locally. iCloud sync failed.")
            if let idx = sessions.firstIndex(where: { $0.id == sessionID }) {
                sessions[idx] = sess
                saveLocal()
            }
        }
    }

    func updateSessionMeta(sessionID: Int64, label: String? = nil, opponent: String? = nil, performanceRating: Int? = nil) async {
        markSyncAttempt()
        guard var sess = sessions.first(where: { $0.id == sessionID }) else { return }
        if let label { sess.label = label }
        if let opponent { sess.opponent = opponent }
        if let performanceRating { sess.performanceRating = performanceRating }
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
            markSyncSuccess()
        } catch {
            lastError = error.localizedDescription
            syncStatus = .localOnly("Updated locally. iCloud sync failed.")
            markSyncFailure("Updated locally. iCloud sync failed.")
            if let idx = sessions.firstIndex(where: { $0.id == sessionID }) {
                sessions[idx] = sess
                saveLocal()
            }
        }
    }

    func deleteSessions(ids: [Int64]) async {
        markSyncAttempt()
        do {
            try await service.deleteSessions(ids)
            sessions.removeAll { ids.contains($0.id) }
            saveLocal()
            lastError = nil
            syncStatus = .synced
            markSyncSuccess()
        } catch {
            lastError = error.localizedDescription
            syncStatus = .localOnly("Delete saved locally. iCloud sync failed.")
            markSyncFailure("Delete saved locally. iCloud sync failed.")
        }
    }

    func exportJSON() -> Data? {
        JSONTransfer.exportSessions(sessions)
    }

    func importJSON(_ data: Data) async {
        markSyncAttempt()
        do {
            let newSessions = try JSONTransfer.importSessions(data)
            try await replaceAllSessions(newSessions)
            lastError = nil
            syncStatus = .synced
            markSyncSuccess()
        } catch {
            lastError = error.localizedDescription
            syncStatus = .error("Import failed")
            markSyncFailure("Import failed")
        }
    }

    func restoreSampleData() async {
        markSyncAttempt()
        let sample = SampleData.makeSessions()
        do {
            let existingIDs = sessions.map { $0.id }
            try await service.replaceAllSessions(existingIDs: existingIDs, with: sample)
            sessions = sample
            saveLocal()
            UserDefaults.standard.set(true, forKey: seedFlagKey)
            lastError = nil
            syncStatus = .synced
            markSyncSuccess()
        } catch {
            sessions = sample
            saveLocal()
            UserDefaults.standard.set(true, forKey: seedFlagKey)
            lastError = error.localizedDescription
            syncStatus = .localOnly("Sample data saved locally only")
            markSyncFailure("Sample data saved locally only")
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

    private func markSyncAttempt() {
        lastSyncAttemptAt = Date()
    }

    private func markSyncSuccess() {
        lastSyncSuccessAt = Date()
        lastSyncFailureReason = nil
    }

    private func markSyncFailure(_ reason: String) {
        lastSyncFailureReason = reason
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

// MARK: - Auth Store (Sign in with Apple)

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var isSignedIn: Bool = false
    @Published private(set) var appleUserID: String?
    @Published private(set) var displayName: String?
    @Published private(set) var email: String?
    @Published private(set) var lastAuthDate: Date?
    @Published var lastError: String?

    private enum Keys {
        static let service = "com.poolstats.auth"
        static let account = "appleUserID"
        static let displayName = "auth.displayName"
        static let email = "auth.email"
        static let lastAuthDate = "auth.lastAuthDate"
    }

    init() {
        loadPersisted()
        Task { await refreshCredentialState() }
    }

    func signIn() {
        lastError = nil
    }

    func signIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                lastError = "Sign in failed. Could not read Apple ID credential."
                return
            }
            apply(credential: credential)
        case .failure(let error):
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                return
            }
            lastError = error.localizedDescription
        }
    }

    func signOutLocal() {
        _ = keychainDeleteUserID()
        clearMetadata()
        isSignedIn = false
        appleUserID = nil
        displayName = nil
        email = nil
        lastAuthDate = nil
        lastError = nil
    }

    func refreshCredentialState() async {
        guard let userID = keychainReadUserID(), !userID.isEmpty else {
            isSignedIn = false
            appleUserID = nil
            return
        }

        do {
            let state = try await credentialState(for: userID)
            switch state {
            case .authorized:
                isSignedIn = true
                appleUserID = userID
                loadMetadata()
            case .revoked, .notFound, .transferred:
                signOutLocal()
            default:
                isSignedIn = false
                appleUserID = userID
            }
        } catch {
            // Keep the existing local auth data and degrade gracefully when Apple checks fail.
            lastError = "Could not verify Apple sign-in state right now."
            isSignedIn = true
            appleUserID = userID
            loadMetadata()
        }
    }

    var maskedUserID: String {
        guard let appleUserID, !appleUserID.isEmpty else { return "—" }
        if appleUserID.count <= 10 { return appleUserID }
        let prefix = appleUserID.prefix(4)
        let suffix = appleUserID.suffix(4)
        return "\(prefix)…\(suffix)"
    }

    private func apply(credential: ASAuthorizationAppleIDCredential) {
        let userID = credential.user
        guard !userID.isEmpty else {
            lastError = "Sign in failed. Missing Apple user id."
            return
        }

        let formatter = PersonNameComponentsFormatter()
        let newName = credential.fullName.flatMap { formatter.string(from: $0) }.flatMap {
            let trimmed = $0.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        let newEmail = credential.email?.trimmingCharacters(in: .whitespacesAndNewlines)

        if let newName { displayName = newName }
        if let newEmail, !newEmail.isEmpty { email = newEmail }

        lastAuthDate = Date()
        appleUserID = userID
        isSignedIn = true
        lastError = nil

        _ = keychainSaveUserID(userID)
        saveMetadata()
    }

    private func credentialState(for userID: String) async throws -> ASAuthorizationAppleIDProvider.CredentialState {
        try await withCheckedThrowingContinuation { continuation in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { state, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: state)
                }
            }
        }
    }

    private func loadPersisted() {
        if let userID = keychainReadUserID(), !userID.isEmpty {
            appleUserID = userID
            isSignedIn = true
        }
        loadMetadata()
    }

    private func loadMetadata() {
        displayName = UserDefaults.standard.string(forKey: Keys.displayName)
        email = UserDefaults.standard.string(forKey: Keys.email)
        if let ts = UserDefaults.standard.object(forKey: Keys.lastAuthDate) as? TimeInterval {
            lastAuthDate = Date(timeIntervalSince1970: ts)
        }
    }

    private func saveMetadata() {
        if let displayName {
            UserDefaults.standard.set(displayName, forKey: Keys.displayName)
        }
        if let email {
            UserDefaults.standard.set(email, forKey: Keys.email)
        }
        if let lastAuthDate {
            UserDefaults.standard.set(lastAuthDate.timeIntervalSince1970, forKey: Keys.lastAuthDate)
        }
    }

    private func clearMetadata() {
        UserDefaults.standard.removeObject(forKey: Keys.displayName)
        UserDefaults.standard.removeObject(forKey: Keys.email)
        UserDefaults.standard.removeObject(forKey: Keys.lastAuthDate)
    }

    private func keychainSaveUserID(_ userID: String) -> Bool {
        guard let data = userID.data(using: .utf8) else { return false }
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Keys.service,
            kSecAttrAccount: Keys.account
        ]
        SecItemDelete(query as CFDictionary)

        let attributes: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Keys.service,
            kSecAttrAccount: Keys.account,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
    }

    private func keychainReadUserID() -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Keys.service,
            kSecAttrAccount: Keys.account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let string = String(data: data, encoding: .utf8) else { return nil }
        return string
    }

    private func keychainDeleteUserID() -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Keys.service,
            kSecAttrAccount: Keys.account
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
