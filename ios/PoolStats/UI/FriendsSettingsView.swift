import SwiftUI

struct FriendsSettingsView: View {
    @EnvironmentObject private var profileStore: PlayerProfileStore
    @EnvironmentObject private var socialProfileStore: SocialProfileStore
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var opponentStore: OpponentStore
    @State private var didCopyFriendCode: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            publicProfileCard
        }
        .task {
            if socialProfileStore.displayName.isEmpty {
                socialProfileStore.displayName = profileStore.profile.nickname
            }
            await socialProfileStore.refresh()
            await socialProfileStore.refreshIncomingShares()
            await socialProfileStore.refreshOutgoingShares()
        }
    }

    private var publicProfileCard: some View {
        SectionCard(title: "Friends & sharing") {
            VStack(alignment: .leading, spacing: 12) {
                socialPanel(
                    title: "Public profile",
                    subtitle: "Set a public display name and friend code so people can find you."
                ) {
                    FriendsPublicProfileSection(didCopyFriendCode: $didCopyFriendCode)
                }

                socialPanel(
                    title: "Friends",
                    subtitle: "Search by friend code, save people you play with, and keep them ready for match sharing."
                ) {
                    friendLookupSection
                    friendsListSection
                }

                socialPanel(
                    title: "Shared matches",
                    subtitle: "Bring incoming matches into History and keep tabs on the ones you’ve sent out."
                ) {
                    incomingMatchSharesSection
                    outgoingMatchSharesSection
                }
            }
        }
    }

    private var friendLookupSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Add friend")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.text2)
                Spacer(minLength: 0)
                if !socialProfileStore.friendCodeQuery.isEmpty {
                    Button("Clear") {
                        socialProfileStore.resetFriendLookup()
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(Theme.muted)
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 8) {
                TextField("PS-ABC-123", text: $socialProfileStore.friendCodeQuery)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.subheadline.monospaced())
                    .foregroundColor(Theme.text)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                    .background(Theme.panel2)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
                    .onChange(of: socialProfileStore.friendCodeQuery) { value in
                        let compact = value.uppercased().filter { $0.isLetter || $0.isNumber || $0 == "-" }
                        if compact != value { socialProfileStore.friendCodeQuery = compact }
                    }

                Button {
                    Task {
                        await socialProfileStore.lookupFriendByCode()
                    }
                } label: {
                    HStack(spacing: 6) {
                        if case .searching = socialProfileStore.friendLookupState {
                            ProgressView()
                                .tint(Theme.text)
                        }
                        Text("Search")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(Theme.text)
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .background(canSearchFriend ? Theme.purple.opacity(0.24) : Theme.panel2)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(canSearchFriend ? Theme.purple.opacity(0.7) : Theme.border, lineWidth: 0.8)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!canSearchFriend)
            }

            friendLookupResult
        }
    }

    @ViewBuilder
    private var friendLookupResult: some View {
        switch socialProfileStore.friendLookupState {
        case .idle:
            Text("Search by friend code to save a player and share completed matches.")
                .font(.caption2)
                .foregroundColor(Theme.muted)
        case .searching:
            EmptyView()
        case .found(let found):
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(found.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.text)
                    Text(found.friendCode)
                        .font(.caption2.monospaced())
                        .foregroundColor(Theme.muted)
                }
                Spacer(minLength: 0)
                Button {
                    if let friend = socialProfileStore.addFoundFriend() {
                        opponentStore.addOpponent(name: friend.displayName)
                    }
                } label: {
                    Text("Add")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Theme.green.opacity(0.12))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.green.opacity(0.5), lineWidth: 0.7))
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            .background(Theme.panel2)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.teal.opacity(0.35), lineWidth: 0.7))
        case .added(let friend):
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Theme.green)
                Text(String(format: NSLocalizedString("Added %@", comment: ""), friend.displayName))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.green)
                Spacer(minLength: 0)
            }
        case .failed(let message):
            Text(message)
                .font(.caption2)
                .foregroundColor(Theme.red)
                .lineLimit(3)
        }
    }

    private var friendsListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Friends")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.text2)
                Spacer(minLength: 0)
                if !socialProfileStore.friends.isEmpty {
                    Button {
                        Task {
                            await socialProfileStore.refreshFriends()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption.weight(.bold))
                            .foregroundColor(Theme.teal)
                            .frame(width: 28, height: 28)
                            .background(Theme.teal.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }

            if socialProfileStore.friends.isEmpty {
                emptyState("No friends saved yet.")
            } else {
                VStack(spacing: 8) {
                    ForEach(socialProfileStore.friends) { friend in
                        friendRow(friend)
                    }
                }
            }
        }
    }

    private func friendRow(_ friend: SocialFriend) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Theme.teal.opacity(0.18))
                .frame(width: 34, height: 34)
                .overlay(
                    Text(friend.displayName.prefix(1).uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundColor(Theme.teal)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(friend.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.text)
                    .lineLimit(1)
                Text(friend.friendCode)
                    .font(.caption2.monospaced())
                    .foregroundColor(Theme.muted)
            }

            Spacer(minLength: 0)

            Button {
                opponentStore.addOpponent(name: friend.displayName)
            } label: {
                actionChip(label: "Add", systemName: "person.badge.plus", color: Theme.green)
            }
            .buttonStyle(.plain)

            Button {
                socialProfileStore.removeFriend(friendCode: friend.friendCode)
            } label: {
                actionChip(label: "Remove", systemName: "trash", color: Theme.red)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Theme.panel2)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
    }

    private var incomingMatchSharesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Incoming")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.text2)
                    Text("Accept matches friends send to your history.")
                        .font(.caption2)
                        .foregroundColor(Theme.muted.opacity(0.85))
                }

                Spacer(minLength: 0)

                if pendingIncomingShareCount > 0 {
                    Text("\(pendingIncomingShareCount)")
                        .font(.caption2.weight(.black).monospacedDigit())
                        .foregroundColor(Theme.bg)
                        .frame(minWidth: 20, minHeight: 20)
                        .background(Theme.amber)
                        .clipShape(Capsule())
                }

#if DEBUG
                if socialProfileStore.profile != nil {
                    Button {
                        socialProfileStore.simulateIncomingMatchShare()
                    } label: {
                        actionChip(label: "Simulate", systemName: "sparkles", color: Theme.purple)
                    }
                    .buttonStyle(.plain)
                }
#endif

                Button {
                    Task {
                        await socialProfileStore.refreshIncomingShares()
                    }
                } label: {
                    Image(systemName: incomingSharesAreLoading ? "hourglass" : "arrow.clockwise")
                        .font(.caption.weight(.bold))
                        .foregroundColor(Theme.teal)
                        .frame(width: 28, height: 28)
                        .background(Theme.teal.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(incomingSharesAreLoading)
            }

            if socialProfileStore.profile == nil {
                emptyState("Create your public profile first so friends know where to send matches.")
            } else if socialProfileStore.incomingShares.isEmpty {
                emptyState("No shared matches waiting.")
            } else {
                VStack(spacing: 8) {
                    ForEach(socialProfileStore.incomingShares.prefix(6)) { share in
                        incomingShareRow(share)
                    }
                }
            }

            incomingShareStateMessage
        }
    }

    private var outgoingMatchSharesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sent")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.text2)
                    Text("Track whether friends accepted your shared matches.")
                        .font(.caption2)
                        .foregroundColor(Theme.muted.opacity(0.85))
                }

                Spacer(minLength: 0)

                Button {
                    Task {
                        await socialProfileStore.refreshOutgoingShares()
                    }
                } label: {
                    Image(systemName: outgoingSharesAreLoading ? "hourglass" : "arrow.clockwise")
                        .font(.caption.weight(.bold))
                        .foregroundColor(Theme.teal)
                        .frame(width: 28, height: 28)
                        .background(Theme.teal.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(socialProfileStore.profile == nil || outgoingSharesAreLoading)
            }

            if socialProfileStore.profile == nil {
                emptyState("Create your public profile first before sending matches.")
            } else if socialProfileStore.outgoingShares.isEmpty {
                emptyState("No sent matches yet.")
            } else {
                VStack(spacing: 8) {
                    ForEach(socialProfileStore.outgoingShares.prefix(6)) { share in
                        outgoingShareRow(share)
                    }
                }
            }

            outgoingShareStateMessage
        }
    }

    private func outgoingShareRow(_ share: OutgoingMatchShare) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(outgoingShareAccent(share).opacity(0.16))
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: outgoingShareIcon(share))
                        .font(.caption.weight(.black))
                        .foregroundColor(outgoingShareAccent(share))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(share.recipientDisplayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.text)
                    .lineLimit(1)
                Text(share.sessionLabel)
                    .font(.caption2)
                    .foregroundColor(Theme.text2)
                    .lineLimit(1)
                Text("\(AppFormatters.sessionDate(share.createdAt)) · \(share.scoreText)")
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(Theme.muted)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Text(outgoingShareStatusText(share))
                .font(.caption2.weight(.bold))
                .foregroundColor(outgoingShareAccent(share))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(outgoingShareAccent(share).opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(10)
        .background(Theme.panel2)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
    }

    private func incomingShareRow(_ share: IncomingMatchShare) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(incomingShareAccent(share).opacity(0.16))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: share.isAccepted ? "checkmark" : "person.2")
                            .font(.caption.weight(.black))
                            .foregroundColor(incomingShareAccent(share))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(share.senderDisplayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.text)
                        .lineLimit(1)
                    Text(share.sessionLabel)
                        .font(.caption2)
                        .foregroundColor(Theme.text2)
                        .lineLimit(1)
                Text(
                    "\(AppFormatters.sessionDate(share.createdAt)) · "
                    + String(
                        format: NSLocalizedString("Your score %lld:%lld", comment: ""),
                        share.losses,
                        share.wins
                    )
                )
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(Theme.muted)
                    .lineLimit(1)
                }

                Spacer(minLength: 0)

                Text(incomingShareStatusText(share))
                    .font(.caption2.weight(.bold))
                    .foregroundColor(incomingShareAccent(share))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(incomingShareAccent(share).opacity(0.12))
                    .clipShape(Capsule())
            }

            if share.isPending {
                HStack(spacing: 8) {
                    Button {
                        Task {
                            await socialProfileStore.acceptIncomingShare(share, savingTo: store)
                            opponentStore.addOpponent(name: share.senderDisplayName)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if incomingShareIsAccepting(share) {
                                ProgressView()
                                    .tint(Theme.bg)
                            }
                            Text("Accept")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundColor(Theme.bg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Theme.green)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(incomingShareIsBusy(share))

                    Button {
                        Task {
                            await socialProfileStore.declineIncomingShare(share)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if incomingShareIsDeclining(share) {
                                ProgressView()
                                    .tint(Theme.red)
                            }
                            Text("Decline")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundColor(Theme.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Theme.red.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Theme.red.opacity(0.5), lineWidth: 0.7)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(incomingShareIsBusy(share))
                }
            }
        }
        .padding(10)
        .background(Theme.panel2)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
    }

    @ViewBuilder
    private var incomingShareStateMessage: some View {
        switch socialProfileStore.incomingShareState {
        case .accepted(let share):
            Text(String(format: NSLocalizedString("Accepted %@. It is now in History.", comment: ""), share.sessionLabel))
                .font(.caption2.weight(.semibold))
                .foregroundColor(Theme.green)
        case .declined(let share):
            Text(String(format: NSLocalizedString("Declined match from %@.", comment: ""), share.senderDisplayName))
                .font(.caption2.weight(.semibold))
                .foregroundColor(Theme.muted)
        case .failed(let message):
            Text(message)
                .font(.caption2)
                .foregroundColor(Theme.red)
                .lineLimit(3)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var outgoingShareStateMessage: some View {
        switch socialProfileStore.outgoingShareRefreshState {
        case .synced(let date):
            Text(String(format: NSLocalizedString("Sent status refreshed %@.", comment: ""), AppFormatters.shortDate(date)))
                .font(.caption2.weight(.semibold))
                .foregroundColor(Theme.green)
        case .failed(let message):
            Text(message)
                .font(.caption2)
                .foregroundColor(Theme.red)
                .lineLimit(3)
        default:
            EmptyView()
        }
    }

    private var canSearchFriend: Bool {
        SocialProfileStore.isValidFriendCode(socialProfileStore.friendCodeQuery)
        && socialProfileStore.friendLookupState != .searching
    }

    private var pendingIncomingShareCount: Int {
        socialProfileStore.incomingShares.filter(\.isPending).count
    }

    private var incomingSharesAreLoading: Bool {
        if case .loading = socialProfileStore.incomingShareState { return true }
        return false
    }

    private var outgoingSharesAreLoading: Bool {
        if case .loading = socialProfileStore.outgoingShareRefreshState { return true }
        return false
    }

    private func incomingShareIsAccepting(_ share: IncomingMatchShare) -> Bool {
        if case .accepting(let id) = socialProfileStore.incomingShareState {
            return id == share.inviteUUID
        }
        return false
    }

    private func incomingShareIsDeclining(_ share: IncomingMatchShare) -> Bool {
        if case .declining(let id) = socialProfileStore.incomingShareState {
            return id == share.inviteUUID
        }
        return false
    }

    private func incomingShareIsBusy(_ share: IncomingMatchShare) -> Bool {
        incomingShareIsAccepting(share) || incomingShareIsDeclining(share)
    }

    private func incomingShareStatusText(_ share: IncomingMatchShare) -> String {
        if share.isAccepted { return NSLocalizedString("Accepted", comment: "") }
        if share.isDeclined { return NSLocalizedString("Declined", comment: "") }
        return NSLocalizedString("Pending", comment: "")
    }

    private func incomingShareAccent(_ share: IncomingMatchShare) -> Color {
        if share.isAccepted { return Theme.green }
        if share.isDeclined { return Theme.muted }
        return Theme.amber
    }

    private func outgoingShareStatusText(_ share: OutgoingMatchShare) -> String {
        if share.isAccepted { return NSLocalizedString("Accepted", comment: "") }
        if share.isDeclined { return NSLocalizedString("Declined", comment: "") }
        if share.isFailed { return NSLocalizedString("Failed", comment: "") }
        return NSLocalizedString("Pending", comment: "")
    }

    private func outgoingShareAccent(_ share: OutgoingMatchShare) -> Color {
        if share.isAccepted { return Theme.green }
        if share.isDeclined { return Theme.red }
        if share.isFailed { return Theme.red }
        return Theme.amber
    }

    private func outgoingShareIcon(_ share: OutgoingMatchShare) -> String {
        if share.isAccepted { return "checkmark" }
        if share.isDeclined { return "xmark" }
        if share.isFailed { return "exclamationmark" }
        return "paperplane.fill"
    }

    private func socialPanel<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(title))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.text)
                Text(LocalizedStringKey(subtitle))
                    .font(.caption2)
                    .foregroundColor(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            content()
        }
        .padding(12)
        .background(Theme.panel2.opacity(0.42))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.border.opacity(0.65), lineWidth: 0.5)
        )
    }

    private func emptyState(_ message: String) -> some View {
        Text(LocalizedStringKey(message))
            .font(.caption2)
            .foregroundColor(Theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Theme.panel2.opacity(0.7))
            .cornerRadius(10)
    }

    private func actionChip(label: String, systemName: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemName)
                .font(.caption2.weight(.bold))
            Text(LocalizedStringKey(label))
                .font(.caption2.weight(.semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 0.6))
    }
}
