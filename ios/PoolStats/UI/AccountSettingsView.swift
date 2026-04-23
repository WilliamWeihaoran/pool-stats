import SwiftUI
import AuthenticationServices

struct AccountSettingsView: View {
    @EnvironmentObject private var authStore: AuthStore

    var body: some View {
        SectionCard(title: "Account") {
            VStack(alignment: .leading, spacing: 10) {
                infoRow(label: "Data sync", value: "iCloud account")
                infoRow(label: "Profile link", value: "Sign in with Apple")

                HStack(spacing: 6) {
                    Image(systemName: authStore.isSignedIn ? "checkmark.circle.fill" : "minus.circle.fill")
                        .foregroundColor(authStore.isSignedIn ? Theme.green : Theme.text2)
                        .font(.caption)
                    Text(authStore.isSignedIn ? "Auth linked" : "Not linked")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.text2)
                }

                if authStore.isSignedIn {
                    infoRow(label: "Name", value: authStore.displayName ?? "—")
                    infoRow(label: "Email", value: authStore.email ?? "—")
                    infoRow(label: "Apple ID", value: authStore.maskedUserID)
                    infoRow(label: "Last linked", value: authStore.lastAuthDate.map(AppFormatters.sessionDate) ?? "—")

                    Button(role: .destructive) {
                        authStore.signOutLocal()
                    } label: {
                        Text("Sign out")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(Theme.red)
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
                }

                if let error = authStore.lastError, !error.isEmpty {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(Theme.amber)
                }
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
}
