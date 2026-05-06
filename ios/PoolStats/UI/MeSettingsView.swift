import SwiftUI

struct MeSettingsView: View {
    @EnvironmentObject private var profileStore: PlayerProfileStore
    @EnvironmentObject private var socialProfileStore: SocialProfileStore
    @EnvironmentObject private var goalsStore: GoalsStore
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var opponentStore: OpponentStore
    @Environment(\.dismiss) private var dismiss

    @State private var baselineFargoText: String = ""
    @State private var pendingDedication: DedicationLevel?
    @State private var nicknameText: String = ""
    @State private var didCopyFriendCode: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            // Nickname
            SectionCard(title: "Nickname") {
                VStack(alignment: .leading, spacing: 6) {
                    TextField("e.g. Haoran", text: $nicknameText)
                        .font(.subheadline)
                        .foregroundColor(Theme.text)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Theme.panel2)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 0.5))
                        .onChange(of: nicknameText) { value in
                            profileStore.updateProfile { $0.nickname = value }
                        }
                    Text("Shown above your score in the lite scoreboard. Defaults to \"Me\".")
                        .font(.caption2)
                        .foregroundColor(Theme.muted)
                }
            }

            publicProfileCard

            // Skill level
            SectionCard(title: "Skill level") {
                VStack(spacing: 0) {
                    ForEach(SkillLevel.allCases) { level in
                        let selected = profileStore.profile.skillLevel == level
                        Button {
                            profileStore.updateProfile {
                                $0.skillLevel = level
                                $0.baselineFargo = level.defaultFargo
                            }
                            baselineFargoText = "\(profileStore.profile.clampedBaseline)"
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selected ? "record.circle.fill" : "circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(selected ? Theme.purple : Theme.border)
                                Text(level.label)
                                    .font(.subheadline)
                                    .foregroundColor(selected ? Theme.text : Theme.text2)
                                Spacer(minLength: 0)
                                Text(level.fargoRange)
                                    .font(.caption2.monospacedDigit())
                                    .foregroundColor(selected ? Theme.purple : Theme.muted)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(selected ? Theme.purple.opacity(0.1) : Theme.panel2)
                                    .cornerRadius(6)
                            }
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if level != SkillLevel.allCases.last {
                            Divider().overlay(Theme.border)
                        }
                    }

                    Divider().overlay(Theme.border)

                    HStack {
                        Text("My Fargo rating")
                            .font(.subheadline)
                            .foregroundColor(Theme.text2)
                        Spacer(minLength: 0)
                        TextField("0–850", text: $baselineFargoText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.subheadline.monospacedDigit())
                            .foregroundColor(Theme.text)
                            .frame(width: 56)
                            .onChange(of: baselineFargoText) { value in
                                let filtered = value.filter(\.isNumber)
                                if filtered != value { baselineFargoText = filtered }
                                profileStore.updateProfile {
                                    $0.baselineFargo = min(max(Int(filtered) ?? 0, 0), 850)
                                }
                            }
                        Text("/ 850")
                            .font(.caption2)
                            .foregroundColor(Theme.muted)
                    }
                    .padding(.vertical, 10)
                }
            }

            // Dedication
            SectionCard(title: "Dedication") {
                VStack(spacing: 0) {
                    ForEach(DedicationLevel.allCases) { level in
                        let selected = profileStore.profile.dedication == level
                        let accent = dedicationAccentColor(level)
                        Button {
                            guard level != profileStore.profile.dedication else { return }
                            pendingDedication = level
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selected ? "record.circle.fill" : "circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(selected ? accent : Theme.border)
                                Text(level.label)
                                    .font(.subheadline)
                                    .foregroundColor(selected ? Theme.text : Theme.text2)
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if level != DedicationLevel.allCases.last {
                            Divider().overlay(Theme.border)
                        }
                    }
                }
            }

            // Game & frequency
            SectionCard(title: "Game & frequency") {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Primary game")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Theme.muted)
                        HStack(spacing: 8) {
                            ForEach(PrimaryGame.allCases) { game in
                                let selected = profileStore.profile.primaryGame == game
                                Button {
                                    profileStore.updateProfile { $0.primaryGame = game }
                                } label: {
                                    Text(game.label)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(selected ? Theme.text : Theme.text2)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 40)
                                        .background(selected ? Theme.teal.opacity(0.12) : Theme.panel2)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(selected ? Theme.teal : Theme.border,
                                                        lineWidth: selected ? 1.2 : 0.5)
                                        )
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("How often per week")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Theme.muted)
                        HStack(spacing: 8) {
                            ForEach(FrequencyBand.allCases) { band in
                                let selected = profileStore.profile.weeklyFrequencyBand == band
                                Button {
                                    profileStore.updateProfile { $0.weeklyFrequencyBand = band }
                                } label: {
                                    VStack(spacing: 2) {
                                        Text(band.frequency)
                                            .font(.subheadline.weight(.bold).monospacedDigit())
                                            .foregroundColor(selected ? Theme.text : Theme.text2)
                                        Text(band.sublabel)
                                            .font(.caption2)
                                            .foregroundColor(selected ? Theme.amber : Theme.muted)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(selected ? Theme.amber.opacity(0.12) : Theme.panel2)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selected ? Theme.amber : Theme.border,
                                                    lineWidth: selected ? 1.2 : 0.5)
                                    )
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            Button {
                profileStore.requestRerunOnboarding()
                dismiss()
            } label: {
                Text("Re-run onboarding")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.purple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.purple.opacity(0.12))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.purple.opacity(0.45), lineWidth: 0.8))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            SectionCard(title: "Me") {
                VStack(spacing: 10) {
                    infoRow(label: "Favorite opponent", value: favoriteOpponent)
                    infoRow(label: "Biggest leak", value: Analytics.biggestLeakSummary(Analytics.matchRacks(store.sessions)))
                    infoRow(label: "Latest session", value: latestSessionText)
                }
            }
        }
        .task {
            baselineFargoText = "\(profileStore.profile.clampedBaseline)"
            nicknameText = profileStore.profile.nickname
            if socialProfileStore.displayName.isEmpty {
                socialProfileStore.displayName = profileStore.profile.nickname
            }
            await socialProfileStore.refresh()
        }
        .alert("Regenerate starter goals?", isPresented: Binding(
            get: { pendingDedication != nil },
            set: { if !$0 { pendingDedication = nil } }
        )) {
            Button("Keep current goals", role: .cancel) {
                if let next = pendingDedication {
                    profileStore.updateProfile { $0.dedication = next }
                }
                pendingDedication = nil
            }
            Button("Regenerate") {
                if let next = pendingDedication {
                    profileStore.updateProfile { $0.dedication = next }
                    let starter = goalsStore.starterGoals(from: profileStore.profile)
                    goalsStore.applyStarterGoals(starter, replaceExistingStarter: true)
                }
                pendingDedication = nil
            }
        } message: {
            Text("Use your new dedication level to regenerate starter-generated goals?")
        }
    }

    private func dedicationAccentColor(_ level: DedicationLevel) -> Color {
        switch level {
        case .justForFun: return Theme.muted
        case .maybe: return Theme.teal
        case .neutral: return Theme.teal
        case .yes: return Theme.green
        case .veryMuch: return Theme.purple
        }
    }

    private var publicProfileCard: some View {
        SectionCard(title: "Public profile") {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Display name")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.muted)
                    TextField("e.g. Haoran", text: $socialProfileStore.displayName)
                        .font(.subheadline)
                        .foregroundColor(Theme.text)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Theme.panel2)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 0.5))
                }

                if let profile = socialProfileStore.profile {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Friend code")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Theme.muted)

                        HStack(spacing: 10) {
                            Text(profile.friendCode)
                                .font(.title3.weight(.bold).monospaced())
                                .foregroundColor(Theme.teal)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            Button {
                                socialProfileStore.copyFriendCode()
                                showCopiedState()
                            } label: {
                                Text(didCopyFriendCode ? "Copied" : "Copy")
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
                } else {
                    Text("Create a public display name and friend code. Friend lookup and match sharing come in the next phases.")
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                }

                HStack(spacing: 8) {
                    Circle()
                        .fill(publicProfileStatusColor)
                        .frame(width: 7, height: 7)
                    Text(socialProfileStore.statusText)
                        .font(.caption2)
                        .foregroundColor(Theme.muted)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                }

                if let error = socialProfileStore.lastError, !error.isEmpty {
                    Text(error)
                        .font(.caption2)
                        .foregroundColor(Theme.red)
                        .lineLimit(3)
                }

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

                Divider().overlay(Theme.border.opacity(0.8))

                friendLookupSection

                friendsListSection
            }
        }
    }

    private var friendLookupSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Add friend")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.muted)
                Spacer(minLength: 0)
                if !socialProfileStore.friendCodeQuery.isEmpty {
                    Button {
                        socialProfileStore.resetFriendLookup()
                    } label: {
                        Text("Clear")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(Theme.muted)
                    }
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
            Text("Search by friend code to save a player locally. Match sharing comes in a later phase.")
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
                Text("Added \(friend.displayName)")
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
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.muted)
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
                Text("No friends saved yet.")
                    .font(.caption2)
                    .foregroundColor(Theme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Theme.panel2.opacity(0.7))
                    .cornerRadius(10)
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
                Image(systemName: "person.badge.plus")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Theme.green)
                    .frame(width: 30, height: 30)
                    .background(Theme.green.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Button {
                socialProfileStore.removeFriend(friendCode: friend.friendCode)
            } label: {
                Image(systemName: "trash")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Theme.red)
                    .frame(width: 30, height: 30)
                    .background(Theme.red.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Theme.panel2)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
    }

    private var canSearchFriend: Bool {
        SocialProfileStore.isValidFriendCode(socialProfileStore.friendCodeQuery)
        && socialProfileStore.friendLookupState != .searching
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

    private var favoriteOpponent: String {
        opponentStore.favoriteOpponent(from: store.sessions)
    }

    private var latestSessionText: String {
        guard let latest = store.sessions.max(by: { $0.ts < $1.ts }) else { return "—" }
        let opp = latest.opponent.trimmingCharacters(in: .whitespaces)
        let game = latest.gameLabel
        let mode = latest.typeLabel
        let bits = [mode, game, opp.isEmpty ? nil : "vs \(opp)"]
        return bits.compactMap { $0 }.joined(separator: " · ")
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
