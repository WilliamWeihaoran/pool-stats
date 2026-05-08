import SwiftUI

enum SettingsSection: String, CaseIterable, Hashable {
    case me
    case account
    case friends
    case opponents
    case history
    case stats
    case appearance
    case data
    case about

    var title: String {
        switch self {
        case .me: return "Me"
        case .account: return "Account"
        case .friends: return "Friends"
        case .opponents: return "Opponents"
        case .history: return "History"
        case .stats: return "Stats"
        case .appearance: return "Appearance"
        case .data: return "Data"
        case .about: return "About"
        }
    }

    var subtitle: String {
        switch self {
        case .me: return "Player profile, Fargo baseline, and personal stats"
        case .account: return "iCloud sync and Sign in with Apple"
        case .friends: return "Friend code, saved friends, and shared matches"
        case .opponents: return "Add, edit, favorite, and compare opponents"
        case .history: return "Review past sessions and summaries"
        case .stats: return "Session totals and performance snapshots"
        case .appearance: return "Choose a color theme for the app"
        case .data: return "Sync health and local data tools"
        case .about: return "App version and build information"
        }
    }

    var icon: String {
        switch self {
        case .me: return "person.crop.circle.fill"
        case .account: return "lock.icloud.fill"
        case .friends: return "person.2.wave.2.fill"
        case .opponents: return "person.2.fill"
        case .history: return "clock.arrow.circlepath"
        case .stats: return "chart.bar.fill"
        case .appearance: return "paintbrush.fill"
        case .data: return "icloud.and.arrow.down.fill"
        case .about: return "info.circle.fill"
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var socialProfileStore: SocialProfileStore
    private let tabBarClearance: CGFloat = 74

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    header
                    sectionList
                }
                .padding(.horizontal, Layout.pagePadding)
                .padding(.top, 0)
                .padding(.bottom, 12 + tabBarClearance)
            }
            .background(Theme.bg)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: SettingsSection.self) { section in
                SettingsDetailView(section: section)
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
        .appBackSwipeEnabled()
        .task {
            guard socialProfileStore.profile != nil else { return }
            await socialProfileStore.refreshIncomingShares()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Settings")
                .font(.title.bold())
                .foregroundColor(Theme.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    private var sectionList: some View {
        VStack(spacing: 12) {
            ForEach(settingGroups) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.title)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.text2)
                        .padding(.horizontal, 2)
                    VStack(spacing: 8) {
                        ForEach(group.sections, id: \.self) { section in
                            NavigationLink(value: section) {
                                SettingsSectionRow(section: section, badgeText: badgeText(for: section))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var settingGroups: [SettingsGroup] {
        [
            SettingsGroup(title: "Player", sections: [.me, .account, .stats]),
            SettingsGroup(title: "Sessions", sections: [.history]),
            SettingsGroup(title: "People", sections: [.friends, .opponents]),
            SettingsGroup(title: "App", sections: [.appearance, .data, .about])
        ]
    }

    private func badgeText(for section: SettingsSection) -> String? {
        guard section == .friends else { return nil }
        let pending = socialProfileStore.incomingShares.filter(\.isPending).count
        return pending > 0 ? "\(pending)" : nil
    }
}

private struct SettingsGroup: Identifiable {
    let id = UUID()
    let title: String
    let sections: [SettingsSection]
}

private struct SettingsSectionRow: View {
    let section: SettingsSection
    let badgeText: String?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.panel2)
                    .frame(width: 34, height: 34)
                Image(systemName: section.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(section.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.text)
                Text(section.subtitle)
                    .font(.caption2)
                    .foregroundColor(Theme.text2)
                    .lineLimit(1)
            }

            Spacer(minLength: 10)

            if let badgeText {
                Text(badgeText)
                    .font(.caption2.weight(.black).monospacedDigit())
                    .foregroundColor(Theme.bg)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Theme.amber)
                    .clipShape(Capsule())
                    .accessibilityLabel("\(badgeText) pending shared matches")
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(Theme.muted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(Theme.panel)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
    }

    private var iconColor: Color {
        switch section {
        case .me: return Theme.purple
        case .account: return Theme.teal
        case .friends: return Theme.purple
        case .opponents: return Theme.teal
        case .history: return Theme.amber
        case .stats: return Theme.blue
        case .appearance: return Theme.amber
        case .data: return Theme.green
        case .about: return Theme.text2
        }
    }
}
