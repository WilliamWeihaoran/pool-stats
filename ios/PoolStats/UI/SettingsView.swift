import SwiftUI

enum SettingsSection: String, CaseIterable, Hashable {
    case me
    case account
    case opponents
    case history
    case stats
    case recentForm
    case appearance
    case data
    case about

    var title: String {
        switch self {
        case .me: return "Me"
        case .account: return "Account"
        case .opponents: return "Opponents"
        case .history: return "History"
        case .stats: return "Stats"
        case .recentForm: return "Recent form"
        case .appearance: return "Appearance"
        case .data: return "Data"
        case .about: return "About"
        }
    }

    var subtitle: String {
        switch self {
        case .me: return "Your profile, best opponent, and biggest leak"
        case .account: return "iCloud sync and Sign in with Apple"
        case .opponents: return "Add, edit, favorite, and compare opponents"
        case .history: return "Review past sessions and summaries"
        case .stats: return "Session totals and performance snapshots"
        case .recentForm: return "A quick look at how the last 10 sessions went"
        case .appearance: return "Choose a color theme for the app"
        case .data: return "Sync health and local data tools"
        case .about: return "App version and build information"
        }
    }

    var icon: String {
        switch self {
        case .me: return "person.crop.circle.fill"
        case .account: return "lock.icloud.fill"
        case .opponents: return "person.2.fill"
        case .history: return "clock.arrow.circlepath"
        case .stats: return "chart.bar.fill"
        case .recentForm: return "waveform.path.ecg"
        case .appearance: return "paintbrush.fill"
        case .data: return "icloud.and.arrow.down.fill"
        case .about: return "info.circle.fill"
        }
    }
}

struct SettingsView: View {
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
                                SettingsSectionRow(section: section)
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
            SettingsGroup(title: "Player", sections: [.me, .account, .stats, .recentForm]),
            SettingsGroup(title: "Sessions", sections: [.history]),
            SettingsGroup(title: "People", sections: [.opponents]),
            SettingsGroup(title: "App", sections: [.appearance, .data, .about])
        ]
    }
}

private struct SettingsGroup: Identifiable {
    let id = UUID()
    let title: String
    let sections: [SettingsSection]
}

private struct SettingsSectionRow: View {
    let section: SettingsSection

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
        case .opponents: return Theme.teal
        case .history: return Theme.amber
        case .stats, .recentForm: return Theme.blue
        case .appearance: return Theme.amber
        case .data: return Theme.green
        case .about: return Theme.text2
        }
    }
}
