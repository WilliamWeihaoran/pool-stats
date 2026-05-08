import SwiftUI

struct SettingsDetailView: View {
    let section: SettingsSection
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var opponentStore: OpponentStore
    private let tabBarClearance: CGFloat = 74

    var body: some View {
        Group {
            if section == .history {
                VStack(spacing: 8) {
                    detailHeader
                    HistoryView(showsHeader: false)
                }
                .padding(.horizontal, Layout.pagePadding)
                .padding(.top, 8)
                .background(Theme.bg)
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        detailHeader
                        content
                    }
                    .padding(.horizontal, Layout.pagePadding)
                    .padding(.top, 8)
                    .padding(.bottom, 12 + tabBarClearance)
                }
                .background(Theme.bg)
            }
        }
        .task {
            opponentStore.sync(with: store.sessions)
        }
        .appBackSwipeEnabled()
    }

    private var detailHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            AppBackButton(label: "Back to settings", iconOnly: true)

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
            MeSettingsView()
        case .account:
            AccountSettingsView()
        case .friends:
            FriendsSettingsView()
        case .opponents:
            OpponentManagementView()
        case .history:
            EmptyView()
        case .stats:
            statsSection
        case .appearance:
            AppearanceSettingsView()
        case .data:
            DataSettingsView()
        case .about:
            aboutSection
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

    private var aboutSection: some View {
        SectionCard(title: "About") {
            VStack(alignment: .leading, spacing: 8) {
                infoRow(label: "App", value: appName)
                infoRow(label: "Version", value: appVersion)
                infoRow(label: "Build", value: appBuild)
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

}
