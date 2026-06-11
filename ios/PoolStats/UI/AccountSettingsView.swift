import SwiftUI
import AuthenticationServices

struct AccountSettingsView: View {
    private enum DeletionFlowState: Equatable {
        case idle
        case deleting
        case deleted
        case failed(String)
    }

    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var logStore: SessionLogStore
    @EnvironmentObject private var goalsStore: GoalsStore
    @EnvironmentObject private var opponentStore: OpponentStore
    @EnvironmentObject private var profileStore: PlayerProfileStore
    @EnvironmentObject private var socialProfileStore: SocialProfileStore

    @State private var showDeleteConfirmation = false
    @State private var deletionFlowState: DeletionFlowState = .idle

    private var canDeleteAccount: Bool {
        authStore.isSignedIn
            || socialProfileStore.hasLocalAccountData
            || store.hasLocalAccountDeletionData
            || !goalsStore.goals.isEmpty
            || !opponentStore.profiles.isEmpty
            || profileStore.profile != PlayerProfile()
            || logStore.activeSnapshot != nil
    }

    private var isDeletingAccount: Bool {
        if case .deleting = deletionFlowState { return true }
        return false
    }

    var body: some View {
        SectionCard(title: "Account") {
            VStack(alignment: .leading, spacing: 10) {
                infoRow(label: NSLocalizedString("Data sync", comment: ""), value: NSLocalizedString("iCloud account", comment: ""))
                infoRow(label: NSLocalizedString("Profile link", comment: ""), value: NSLocalizedString("Sign in with Apple", comment: ""))

                HStack(spacing: 6) {
                    Image(systemName: authStore.isSignedIn ? "checkmark.circle.fill" : "minus.circle.fill")
                        .foregroundColor(authStore.isSignedIn ? Theme.green : Theme.text2)
                        .font(.caption)
                    Text(authStore.isSignedIn ? NSLocalizedString("Auth linked", comment: "") : NSLocalizedString("Not linked", comment: ""))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.text2)
                }

                if authStore.isSignedIn {
                    infoRow(label: NSLocalizedString("Email", comment: ""), value: authStore.email ?? "—")
                    infoRow(label: NSLocalizedString("Apple ID", comment: ""), value: authStore.maskedUserID)
                    infoRow(label: NSLocalizedString("Last linked", comment: ""), value: authStore.lastAuthDate.map(AppFormatters.sessionDate) ?? "—")

                    Button(role: .destructive) {
                        authStore.signOutLocal()
                    } label: {
                        Text(NSLocalizedString("Sign out", comment: ""))
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(Theme.red)
                    .disabled(isDeletingAccount)
                } else {
                    SignInWithAppleButton(.signIn) { request in
                        authStore.signIn()
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        authStore.signIn(result: result)
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 44)
                    .cornerRadius(10)
                    .disabled(isDeletingAccount)
                }

                if canDeleteAccount {
                    Text(NSLocalizedString("Deleting the account removes the linked Sign in with Apple profile, public friend code profile, saved friends, shared match records, and session history from this device and iCloud.", comment: ""))
                        .font(.caption)
                        .foregroundColor(Theme.muted)

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack(spacing: 8) {
                            if isDeletingAccount {
                                ProgressView()
                                    .tint(Theme.text)
                            }
                            Text(isDeletingAccount ? NSLocalizedString("Deleting account…", comment: "") : NSLocalizedString("Delete account", comment: ""))
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(Theme.red)
                    .disabled(isDeletingAccount)
                }

                switch deletionFlowState {
                case .idle, .deleting:
                    EmptyView()
                case .deleted:
                    Text(NSLocalizedString("Account deleted.", comment: ""))
                        .font(.caption)
                        .foregroundColor(Theme.green)
                case .failed(let message):
                    Text(message)
                        .font(.caption)
                        .foregroundColor(Theme.amber)
                }

                if let error = authStore.lastError, !error.isEmpty, deletionFlowState == .idle {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(Theme.amber)
                }
            }
        }
        .alert(NSLocalizedString("Delete account?", comment: ""), isPresented: $showDeleteConfirmation) {
            Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) {}
            Button(NSLocalizedString("Delete", comment: ""), role: .destructive) {
                Task { await deleteAccount() }
            }
        } message: {
            Text(NSLocalizedString("This removes your linked Apple sign-in metadata, public profile, saved friends, shared match records, and session history.", comment: ""))
        }
        .onChange(of: authStore.isSignedIn) { isSignedIn in
            if isSignedIn {
                socialProfileStore.resetAccountDeletionState()
                deletionFlowState = .idle
            }
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(Theme.muted)
            Spacer()
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundColor(Theme.text)
        }
    }

    private func deleteAccount() async {
        guard !isDeletingAccount else { return }

        deletionFlowState = .deleting
        authStore.lastError = nil
        var failureMessages: [String] = []
        let shouldDeleteSessionHistory = authStore.isSignedIn || store.hasLocalAccountDeletionData
        let shouldDeleteSocialProfile = socialProfileStore.hasLocalAccountData

        if shouldDeleteSessionHistory {
            do {
                try await store.verifyAccountDeletionReadinessForAccountDeletion()
            } catch {
                failureMessages.append(sessionDeletionFailureMessage())
            }
        }

        if shouldDeleteSocialProfile {
            do {
                try await socialProfileStore.verifyAccountDeletionReadinessForAccountDeletion()
            } catch {
                failureMessages.append(profileDeletionFailureMessage())
            }
        }

        guard failureMessages.isEmpty else {
            deletionFlowState = .failed(failureMessages.joined(separator: "\n\n"))
            return
        }

        if shouldDeleteSessionHistory {
            do {
                try await store.deleteAllUserDataForAccountDeletion()
            } catch {
                failureMessages.append(sessionDeletionFailureMessage())
            }
        }

        if shouldDeleteSocialProfile {
            do {
                try await socialProfileStore.deleteAccountData()
            } catch {
                failureMessages.append(profileDeletionFailureMessage())
            }
        }

        if !failureMessages.isEmpty {
            socialProfileStore.resetAccountDeletionState()
            deletionFlowState = .failed(failureMessages.joined(separator: "\n\n"))
        } else {
            logStore.clearForAccountDeletion()
            goalsStore.clearAll()
            opponentStore.clearAll()
            profileStore.clearForAccountDeletion()
            authStore.signOutLocal()
            socialProfileStore.resetAccountDeletionState()
            deletionFlowState = .deleted
        }
    }

    private func sessionDeletionFailureMessage() -> String {
        let detail = store.lastError?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = NSLocalizedString("Session history cleanup could not be verified in iCloud.", comment: "")
        return String(
            format: NSLocalizedString("Session history: %@", comment: ""),
            (detail?.isEmpty == false ? detail : fallback) ?? fallback
        )
    }

    private func profileDeletionFailureMessage() -> String {
        let detail = socialProfileStore.lastError?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = NSLocalizedString("Public profile and shared match cleanup could not be verified in iCloud.", comment: "")
        return String(
            format: NSLocalizedString("Account profile: %@", comment: ""),
            (detail?.isEmpty == false ? detail : fallback) ?? fallback
        )
    }
}
