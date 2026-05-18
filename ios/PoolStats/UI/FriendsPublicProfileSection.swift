import SwiftUI

struct FriendsPublicProfileSection: View {
    @EnvironmentObject private var socialProfileStore: SocialProfileStore
    @Binding var didCopyFriendCode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            displayNameField

            HStack(spacing: 8) {
                statusBadge(text: socialProfileStatusLabel, color: publicProfileStatusColor)
                Spacer(minLength: 0)
            }

            if let profile = socialProfileStore.profile {
                publicProfileDetails(profile)
            } else {
                emptyState(NSLocalizedString("No public profile yet. Create one to get a friend code and start sharing matches.", comment: ""))
            }

            if let error = socialProfileStore.lastError, !error.isEmpty {
                Text(error)
                    .font(.caption2)
                    .foregroundColor(Theme.red)
                    .lineLimit(3)
            }

            publishButton
        }
    }

    private var displayNameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Display name")
                .font(.caption.weight(.semibold))
                .foregroundColor(Theme.muted)
            TextField("Enter your public name", text: $socialProfileStore.displayName)
                .font(.subheadline)
                .foregroundColor(Theme.text)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Theme.panel2)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 0.5))
        }
    }

    private func publicProfileDetails(_ profile: PublicPlayerProfile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Friend code")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.muted)
                    Text(profile.friendCode)
                        .font(.title3.weight(.bold).monospaced())
                        .foregroundColor(Theme.teal)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Button {
                    socialProfileStore.copyFriendCode()
                    showCopiedState()
                } label: {
                    Text(didCopyFriendCode ? "Copied" : "Copy code")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(didCopyFriendCode ? Theme.green : Theme.teal)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background((didCopyFriendCode ? Theme.green : Theme.teal).opacity(0.12))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            .background(Theme.panel2)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.teal.opacity(0.4), lineWidth: 0.7))

            infoRow(label: "Public record", value: profile.maskedOwnerRecordName)
        }
    }

    private var publishButton: some View {
        Button {
            Task {
                await socialProfileStore.createOrUpdateProfile(displayName: socialProfileStore.displayName)
            }
        } label: {
            HStack(spacing: 8) {
                if case .saving = socialProfileStore.publishState {
                    ProgressView()
                        .tint(Theme.text)
                }
                Text(socialProfileStore.profile == nil ? "Create friend code" : "Publish changes")
                    .font(.caption.weight(.semibold))
            }
            .foregroundColor(Theme.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(socialProfileStore.canPublish ? Theme.teal.opacity(0.24) : Theme.panel2)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(socialProfileStore.canPublish ? Theme.teal.opacity(0.75) : Theme.border, lineWidth: 0.8)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!socialProfileStore.canPublish)
    }

    private var socialProfileStatusLabel: String {
        if socialProfileStore.profile == nil {
            return NSLocalizedString("No public profile yet", comment: "")
        }
        return socialProfileStore.statusText
    }

    private var publicProfileStatusColor: Color {
        switch socialProfileStore.publishState {
        case .synced:
            return Theme.green
        case .saving, .loading:
            return Theme.amber
        case .localOnly:
            return Theme.amber
        case .failed:
            return Theme.red
        case .idle:
            return socialProfileStore.profile == nil ? Theme.muted : Theme.teal
        }
    }

    private func showCopiedState() {
        withAnimation(.easeInOut(duration: 0.15)) {
            didCopyFriendCode = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeInOut(duration: 0.15)) {
                didCopyFriendCode = false
            }
        }
    }

    private func emptyState(_ message: String) -> some View {
        Text(message)
            .font(.caption2)
            .foregroundColor(Theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Theme.panel2.opacity(0.7))
            .cornerRadius(10)
    }

    private func statusBadge(text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(text)
                .font(.caption2.weight(.semibold))
                .foregroundColor(color)
                .lineLimit(2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(LocalizedStringKey(label))
                .font(.caption)
                .foregroundColor(Theme.muted)
            Spacer()
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundColor(Theme.text)
        }
    }
}
