import Foundation
import AuthenticationServices
import Security

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
            // Keep existing local auth data and degrade gracefully when Apple checks fail.
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
