import SwiftUI

struct SettingsDetailView: View {
    let section: SettingsSection
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss

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
                Text(section.title)
                    .font(.title.bold())
                    .foregroundColor(Theme.text)
                Text(section.subtitle)
                    .font(.caption)
                    .foregroundColor(Theme.muted)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(Theme.panel)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.border, lineWidth: 0.5))
    }

    @ViewBuilder
    private var content: some View {
        switch section {
        case .me:
            meSection
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
        SectionCard(title: "Me") {
            VStack(spacing: 10) {
                infoRow(label: "Favorite opponent", value: favoriteOpponent)
                infoRow(label: "Biggest leak", value: Analytics.biggestLeakSummary(Analytics.matchRacks(store.sessions)))
                infoRow(label: "Latest session", value: latestSessionText)
            }
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
                            themeStore.selectedTheme = style
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
        let names = store.sessions
            .map(\.opponent)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard !names.isEmpty else { return "—" }
        let counts = Dictionary(grouping: names, by: { $0 }).mapValues(\.count)
        guard let top = counts.max(by: { $0.value < $1.value }) else { return "—" }
        return top.key
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
