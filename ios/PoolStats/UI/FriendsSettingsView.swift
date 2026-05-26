import SwiftUI

struct FriendsSettingsView: View {
    @Environment(\.openURL) private var openURL
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
                SocialPanel(
                    title: "Public profile",
                    subtitle: "Set a public display name and friend code so people can find you."
                ) {
                    FriendsPublicProfileSection(didCopyFriendCode: $didCopyFriendCode)
                }

                SocialPanel(
                    title: "Friends",
                    subtitle: "Search by friend code, save people you play with, and keep them ready for match sharing."
                ) {
                    friendLookupSection
                    friendsListSection
                    blockedPlayersSection
                    communitySafetySection
                }

                SocialPanel(
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
                    Text(socialProfileStore.presentableDisplayName(found.displayName))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.text)
                    if socialProfileStore.shouldHideDisplayName(found.displayName) {
                        Text("Name hidden for safety. You can report or block this profile.")
                            .font(.caption2)
                            .foregroundColor(Theme.amber)
                            .fixedSize(horizontal: false, vertical: true)
                    }
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
                .disabled(socialProfileStore.shouldHideDisplayName(found.displayName))

                moderationMenu(
                    displayName: found.displayName,
                    friendCode: found.friendCode,
                    reportReason: "Public profile display name or friend sharing account"
                ) {
                    socialProfileStore.block(publicProfile: found)
                }
            }
            .padding(10)
            .background(Theme.panel2)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        socialProfileStore.shouldHideDisplayName(found.displayName)
                            ? Theme.amber.opacity(0.5)
                            : Theme.teal.opacity(0.35),
                        lineWidth: 0.7
                    )
            )
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
                SocialEmptyState(message: "No friends saved yet.")
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
                    Text(socialProfileStore.presentableDisplayName(friend.displayName).prefix(1).uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundColor(Theme.teal)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(socialProfileStore.presentableDisplayName(friend.displayName))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.text)
                    .lineLimit(1)
                if socialProfileStore.shouldHideDisplayName(friend.displayName) {
                    Text("Name hidden for safety.")
                        .font(.caption2)
                        .foregroundColor(Theme.amber)
                }
                Text(friend.friendCode)
                    .font(.caption2.monospaced())
                    .foregroundColor(Theme.muted)
            }

            Spacer(minLength: 0)

            Button {
                opponentStore.addOpponent(name: socialProfileStore.presentableDisplayName(friend.displayName))
            } label: {
                SocialActionChip(label: "Add", systemName: "person.badge.plus", color: Theme.green)
            }
            .buttonStyle(.plain)
            .disabled(socialProfileStore.shouldHideDisplayName(friend.displayName))

            moderationMenu(
                displayName: friend.displayName,
                friendCode: friend.friendCode,
                reportReason: "Saved friend profile or shared-match contact"
            ) {
                socialProfileStore.block(friend: friend)
            }

            Button {
                socialProfileStore.removeFriend(friendCode: friend.friendCode)
            } label: {
                SocialActionChip(label: "Remove", systemName: "trash", color: Theme.red)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Theme.panel2)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
    }

    @ViewBuilder
    private var blockedPlayersSection: some View {
        if !socialProfileStore.blockedPlayers.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Blocked players")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.text2)

                VStack(spacing: 8) {
                    ForEach(socialProfileStore.blockedPlayers) { blocked in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Theme.red.opacity(0.14))
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Image(systemName: "hand.raised.fill")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(Theme.red)
                                )

                            VStack(alignment: .leading, spacing: 3) {
                                Text(socialProfileStore.presentableDisplayName(blocked.displayName))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(Theme.text)
                                Text(blocked.friendCode)
                                    .font(.caption2.monospaced())
                                    .foregroundColor(Theme.muted)
                            }

                            Spacer(minLength: 0)

                            Button {
                                socialProfileStore.unblock(friendCode: blocked.friendCode)
                            } label: {
                                SocialActionChip(label: "Unblock", systemName: "hand.raised.slash", color: Theme.teal)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                        .background(Theme.panel2)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
                    }
                }
            }
        }
    }

    private var communitySafetySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Community safety")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.text2)

            Text("Use the Safety menu on profiles and shared matches to report or block abusive players. Reports go straight to support for review.")
                .font(.caption2)
                .foregroundColor(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Button {
                    openSupportWebsite()
                } label: {
                    SocialActionChip(label: "Support Website", systemName: "safari", color: Theme.teal)
                }
                .buttonStyle(.plain)

                Button {
                    emailSupport()
                } label: {
                    SocialActionChip(label: "Email Support", systemName: "envelope", color: Theme.purple)
                }
                .buttonStyle(.plain)
            }
        }
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
                        SocialActionChip(label: "Simulate", systemName: "sparkles", color: Theme.purple)
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
                SocialEmptyState(message: "Create your public profile first so friends know where to send matches.")
            } else if socialProfileStore.incomingShares.isEmpty {
                SocialEmptyState(message: "No shared matches waiting.")
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
                SocialEmptyState(message: "Create your public profile first before sending matches.")
            } else if socialProfileStore.outgoingShares.isEmpty {
                SocialEmptyState(message: "No sent matches yet.")
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(MatchSharePresentation.accent(for: share).opacity(0.16))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: MatchSharePresentation.icon(for: share))
                            .font(.caption.weight(.black))
                            .foregroundColor(MatchSharePresentation.accent(for: share))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(socialProfileStore.presentableDisplayName(share.recipientDisplayName))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.text)
                        .lineLimit(1)
                    if socialProfileStore.shouldHideDisplayName(share.recipientDisplayName) {
                        Text("Name hidden for safety.")
                            .font(.caption2)
                            .foregroundColor(Theme.amber)
                    }
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

                Text(MatchSharePresentation.statusText(for: share))
                    .font(.caption2.weight(.bold))
                    .foregroundColor(MatchSharePresentation.accent(for: share))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(MatchSharePresentation.accent(for: share).opacity(0.12))
                    .clipShape(Capsule())
            }

            if socialProfileStore.shouldHideDisplayName(share.recipientDisplayName) {
                Text("Name hidden for safety. You can report or block this profile.")
                    .font(.caption2)
                    .foregroundColor(Theme.amber)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                moderationMenu(
                    displayName: share.recipientDisplayName,
                    friendCode: share.recipientFriendCode,
                    reportReason: "Outgoing shared match recipient or public profile"
                ) {
                    socialProfileStore.block(friendCode: share.recipientFriendCode, displayName: share.recipientDisplayName)
                }
                Spacer(minLength: 0)
            }
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
                    .fill(MatchSharePresentation.accent(for: share).opacity(0.16))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: share.isAccepted ? "checkmark" : "person.2")
                            .font(.caption.weight(.black))
                            .foregroundColor(MatchSharePresentation.accent(for: share))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(socialProfileStore.presentableDisplayName(share.senderDisplayName))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.text)
                        .lineLimit(1)
                    if socialProfileStore.shouldHideDisplayName(share.senderDisplayName) {
                        Text("Name hidden for safety.")
                            .font(.caption2)
                            .foregroundColor(Theme.amber)
                    }
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

                Text(MatchSharePresentation.statusText(for: share))
                    .font(.caption2.weight(.bold))
                    .foregroundColor(MatchSharePresentation.accent(for: share))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(MatchSharePresentation.accent(for: share).opacity(0.12))
                    .clipShape(Capsule())
            }

            if share.isPending {
                HStack(spacing: 8) {
                    Button {
                        Task {
                            await socialProfileStore.acceptIncomingShare(share, savingTo: store)
                            if !socialProfileStore.shouldHideDisplayName(share.senderDisplayName) {
                                opponentStore.addOpponent(name: share.senderDisplayName)
                            }
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

            HStack(spacing: 8) {
                moderationMenu(
                    displayName: share.senderDisplayName,
                    friendCode: share.senderFriendCode,
                    reportReason: "Incoming shared match sender or public profile"
                ) {
                    socialProfileStore.block(share: share)
                }
                Spacer(minLength: 0)
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

    private func moderationMenu(
        displayName: String,
        friendCode: String,
        reportReason: String,
        blockAction: @escaping () -> Void
    ) -> some View {
        Menu {
            Button {
                reportProfile(displayName: displayName, friendCode: friendCode, reason: reportReason)
            } label: {
                Label("Report", systemImage: "exclamationmark.bubble")
            }

            Button(role: .destructive) {
                blockAction()
            } label: {
                Label("Block", systemImage: "hand.raised.fill")
            }
        } label: {
            SocialActionChip(label: "Safety", systemName: "shield.lefthalf.filled", color: Theme.amber)
        }
    }

    private func reportProfile(displayName: String, friendCode: String, reason: String) {
        guard let url = socialProfileStore.reportEmailURL(
            displayName: displayName,
            friendCode: friendCode,
            reason: reason
        ) else {
            return
        }
        openURL(url)
    }

    private func openSupportWebsite() {
        guard let url = URL(string: "https://williamweihaoran.github.io/pool-stats/support.html") else { return }
        openURL(url)
    }

    private func emailSupport() {
        guard let url = URL(string: "mailto:william.weihaoran@gmail.com") else { return }
        openURL(url)
    }
}
