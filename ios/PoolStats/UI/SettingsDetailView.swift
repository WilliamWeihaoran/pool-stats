import SwiftUI
import AuthenticationServices

struct SettingsDetailView: View {
    let section: SettingsSection
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var opponentStore: OpponentStore
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var goalsStore: GoalsStore
    @EnvironmentObject private var profileStore: PlayerProfileStore
    @Environment(\.dismiss) private var dismiss
    @State private var baselineFargoText: String = ""
    @State private var pendingDedication: DedicationLevel?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                detailHeader
                content
            }
            .padding(.horizontal, Layout.pagePadding)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(Theme.bg)
        .task {
            opponentStore.sync(with: store.sessions)
            baselineFargoText = "\(profileStore.profile.clampedBaseline)"
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

    private var detailHeader: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.text)
                    .frame(width: 32, height: 32)
                    .background(Theme.panel2)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.muted)
                Text(section.title)
                    .font(.title.bold())
                    .foregroundColor(Theme.text)
                Text(section.subtitle)
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 2)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var content: some View {
        switch section {
        case .me:
            meSection
        case .opponents:
            OpponentManagementView()
        case .stats:
            statsSection
        case .recentForm:
            recentFormSection
        case .appearance:
            appearanceSection
        case .data:
            dataSection
        case .about:
            aboutSection
        }
    }

    private var meSection: some View {
        VStack(spacing: 12) {
            SectionCard(title: "Player profile") {
                VStack(alignment: .leading, spacing: 10) {
                    profileRow(label: "Skill", content: {
                        SegmentedRow(items: SkillLevel.allCases, selection: Binding(
                            get: { profileStore.profile.skillLevel },
                            set: { newValue in
                                profileStore.updateProfile {
                                    $0.skillLevel = newValue
                                    $0.baselineFargo = newValue.defaultFargo
                                }
                                baselineFargoText = "\(profileStore.profile.clampedBaseline)"
                            }
                        )) { $0.label }
                    })

                    profileRow(label: "Baseline Fargo", content: {
                        HStack(spacing: 8) {
                            TextField("0-850", text: $baselineFargoText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .font(.subheadline.monospacedDigit())
                                .foregroundColor(Theme.text)
                                .onChange(of: baselineFargoText) { value in
                                    let filtered = value.filter(\.isNumber)
                                    if filtered != value { baselineFargoText = filtered }
                                    profileStore.updateProfile {
                                        $0.baselineFargo = min(max(Int(filtered) ?? 0, 0), 850)
                                    }
                                }
                            Text("0–850")
                                .font(.caption2)
                                .foregroundColor(Theme.muted)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                        .background(Theme.panel2)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
                    })

                    profileRow(label: "Dedication", content: {
                        SegmentedRow(items: DedicationLevel.allCases, selection: Binding(
                            get: { profileStore.profile.dedication },
                            set: { newValue in
                                guard newValue != profileStore.profile.dedication else { return }
                                pendingDedication = newValue
                            }
                        )) { $0.label }
                    })

                    profileRow(label: "Primary game", content: {
                        SegmentedRow(items: PrimaryGame.allCases, selection: Binding(
                            get: { profileStore.profile.primaryGame },
                            set: { newValue in
                                profileStore.updateProfile { $0.primaryGame = newValue }
                            }
                        )) { $0.label }
                    })

                    profileRow(label: "Frequency", content: {
                        SegmentedRow(items: FrequencyBand.allCases, selection: Binding(
                            get: { profileStore.profile.weeklyFrequencyBand },
                            set: { newValue in
                                profileStore.updateProfile { $0.weeklyFrequencyBand = newValue }
                            }
                        )) { $0.label }
                    })

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
                    }
                    .buttonStyle(.plain)
                }
            }

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

            SectionCard(title: "Me") {
                VStack(spacing: 10) {
                    infoRow(label: "Favorite opponent", value: favoriteOpponent)
                    infoRow(label: "Biggest leak", value: Analytics.biggestLeakSummary(Analytics.matchRacks(store.sessions)))
                    infoRow(label: "Latest session", value: latestSessionText)
                }
            }
        }
    }

    private func profileRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(Theme.muted)
            content()
        }
    }

    private var statsSection: some View {
        let sessions = store.sessions
        let avgRating = averageRatingText
        let bestGame = bestGameText
        let matchWin = matchWinText
        let rackWin = rackWinText
        let practiceCount = sessions.filter { $0.type == "practice" }.count

        return SectionCard(title: "Stats") {
            LazyVGrid(columns: Layout.columns(hSizeClass: nil), spacing: Layout.gridSpacing) {
                StatCard(label: "Sessions", value: "\(sessions.count)")
                StatCard(label: "Match win%", value: matchWin)
                StatCard(label: "Rack win%", value: rackWin)
                StatCard(label: "Avg rating", value: avgRating)
                StatCard(label: "Practice", value: "\(practiceCount)")
                StatCard(label: "Best game", value: bestGame)
            }
        }
    }

    private var recentFormSection: some View {
        SectionCard(title: "Recent form") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Last 10 sessions")
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                    Spacer()
                    Text(recentWinText)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.purple)
                }
                PercentageBar(value: recentWinPct, color: Theme.teal, height: 8)
                HStack {
                    Text("Recent balance")
                        .font(.caption2)
                        .foregroundColor(Theme.text2)
                    Spacer()
                    Text(recentBalanceText)
                        .font(.caption2.weight(.medium))
                        .foregroundColor(Theme.text2)
                }
            }
        }
    }

    private var appearanceSection: some View {
        SectionCard(title: "Appearance") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Themes")
                    .font(.caption)
                    .foregroundColor(Theme.muted)

                LazyVGrid(columns: Layout.twoColumn(), spacing: 10) {
                    ForEach(ThemeStyle.allCases) { style in
                        ThemeChoiceCard(style: style, isOn: themeStore.selectedTheme == style) {
                            themeStore.setTheme(style)
                        }
                    }
                }
            }
        }
    }

    private var dataSection: some View {
        SectionCard(title: "Data") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Sync status")
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                    Spacer()
                    syncBadge
                }

                infoRow(label: "Sync health", value: syncHealthText)
                infoRow(label: "Last cloud sync", value: lastCloudSyncText)
                if let reason = store.lastSyncFailureReason, !reason.isEmpty {
                    Text(reason)
                        .font(.caption)
                        .foregroundColor(Theme.amber)
                }

                Button("Restore sample data") {
                    Task { await store.restoreSampleData() }
                }
                .buttonStyle(.bordered)
                .tint(Theme.purple)

                Text("Sessions are saved locally first and then synced to iCloud.")
                    .font(.caption)
                    .foregroundColor(Theme.text2)
            }
        }
    }

    private var aboutSection: some View {
        SectionCard(title: "About") {
            VStack(alignment: .leading, spacing: 8) {
                infoRow(label: "App", value: appName)
                infoRow(label: "Version", value: appVersion)
                infoRow(label: "Build", value: appBuild)
            }
        }
    }

    private var syncBadge: some View {
        HStack(spacing: 6) {
            Group {
                switch store.syncStatus {
                case .loading, .syncing:
                    ProgressView().progressViewStyle(.circular).tint(Theme.purple)
                case .synced:
                    Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.green)
                case .localOnly:
                    Image(systemName: "tray.and.arrow.down.fill").foregroundColor(Theme.amber)
                case .error:
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(Theme.red)
                }
            }
            .font(.caption2)
            Text(syncStatusText)
                .font(.caption2.weight(.medium))
                .foregroundColor(Theme.text2)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(Theme.panel2)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
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

    private var syncStatusText: String {
        switch store.syncStatus {
        case .loading: return "Loading"
        case .syncing: return "Syncing"
        case .synced: return "iCloud synced"
        case .localOnly: return "Local cache active"
        case .error: return "Sync issue"
        }
    }

    private var syncHealthText: String {
        if let reason = store.lastSyncFailureReason, !reason.isEmpty {
            return "Needs attention"
        }
        if store.lastSyncSuccessAt != nil {
            return "Healthy"
        }
        if store.lastSyncAttemptAt != nil {
            return "Checking"
        }
        return "Unknown"
    }

    private var lastCloudSyncText: String {
        if let last = store.lastSyncSuccessAt {
            return AppFormatters.shortDateTime(last)
        }
        if let attempted = store.lastSyncAttemptAt {
            return "Last attempt \(AppFormatters.shortDateTime(attempted))"
        }
        return "Never"
    }

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "PoolStats"
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    private var averageRatingText: String {
        let ratings = store.sessions.compactMap { $0.performanceRating }
        guard !ratings.isEmpty else { return "—" }
        let avg = Double(ratings.reduce(0, +)) / Double(ratings.count)
        return String(format: "%.1f/10", avg)
    }

    private var bestGameText: String {
        let sessions = store.sessions
        let eight = sessions.filter { $0.game == "8ball" }.count
        let nine = sessions.filter { $0.game == "9ball" }.count
        if eight == 0 && nine == 0 { return "—" }
        if eight == nine { return "Split" }
        return eight > nine ? "8-ball" : "9-ball"
    }

    private var favoriteOpponent: String {
        opponentStore.favoriteOpponent(from: store.sessions)
    }

    private var matchWinText: String {
        let matches = Analytics.matchOnly(store.sessions)
        guard !matches.isEmpty else { return "—" }
        let wins = matches.filter { $0.wins > $0.racks.count / 2 }.count
        return "\(Int(round(Double(wins) / Double(matches.count) * 100)))%"
    }

    private var rackWinText: String {
        let racks = Analytics.matchRacks(store.sessions)
        guard !racks.isEmpty else { return "—" }
        let wins = racks.reduce(0) { $0 + ($1.result == "won" ? 1 : 0) }
        return "\(Int(round(Double(wins) / Double(racks.count) * 100)))%"
    }

    private var latestSessionText: String {
        guard let latest = store.sessions.max(by: { $0.ts < $1.ts }) else { return "—" }
        let opp = latest.opponent.trimmingCharacters(in: .whitespaces)
        let game = latest.gameLabel
        let mode = latest.typeLabel
        let bits = [mode, game, opp.isEmpty ? nil : "vs \(opp)"]
        return bits.compactMap { $0 }.joined(separator: " · ")
    }

    private var recentWinText: String {
        let recent = Array(store.sessions.sorted { $0.ts > $1.ts }.prefix(10))
        guard !recent.isEmpty else { return "—" }
        let matches = recent.filter { $0.type == "match" }
        if matches.isEmpty { return "Practice only" }
        let wins = matches.filter { $0.wins > $0.racks.count / 2 }.count
        return "\(Int(round(Double(wins) / Double(matches.count) * 100)))% match win"
    }

    private var recentBalanceText: String {
        let recent = Array(store.sessions.sorted { $0.ts > $1.ts }.prefix(10))
        guard !recent.isEmpty else { return "—" }
        let matches = recent.filter { $0.type == "match" }
        guard !matches.isEmpty else { return "Practice only" }
        let wins = matches.filter { $0.wins > $0.racks.count / 2 }.count
        let losses = matches.count - wins
        if wins == losses { return "Even" }
        return wins > losses ? "+\(wins - losses)" : "-\(losses - wins)"
    }

    private var recentWinPct: Int {
        let recent = Array(store.sessions.sorted { $0.ts > $1.ts }.prefix(10))
        guard !recent.isEmpty else { return 0 }
        let matches = recent.filter { $0.type == "match" }
        guard !matches.isEmpty else { return 0 }
        let wins = matches.filter { $0.wins > $0.racks.count / 2 }.count
        return Int(round(Double(wins) / Double(matches.count) * 100))
    }
}

private struct ThemeChoiceCard: View {
    let style: ThemeStyle
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        let p = style.palette
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(style.label)
                            .font(.headline)
                            .foregroundColor(p.text)
                        Text(style.subtitle)
                            .font(.caption2)
                            .foregroundColor(p.muted)
                    }
                    Spacer(minLength: 0)
                    if isOn {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(p.purple)
                    }
                }
                RoundedRectangle(cornerRadius: 12)
                    .fill(p.panel)
                    .frame(height: 44)
                    .overlay(
                        VStack(spacing: 6) {
                            HStack(spacing: 6) {
                                Capsule().fill(p.purple.opacity(0.9)).frame(width: 30, height: 6)
                                Capsule().fill(p.teal.opacity(0.85)).frame(width: 18, height: 6)
                                Capsule().fill(p.red.opacity(0.85)).frame(width: 18, height: 6)
                            }
                            HStack {
                                Circle().fill(p.border).frame(width: 7, height: 7)
                                Spacer()
                                Capsule().fill(p.panel2).frame(width: 44, height: 8)
                            }
                            .padding(.horizontal, 8)
                        }
                    )
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isOn ? p.purple.opacity(0.12) : p.bg)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(isOn ? p.purple : p.border, lineWidth: 0.9))
        }
        .buttonStyle(.plain)
    }
}
