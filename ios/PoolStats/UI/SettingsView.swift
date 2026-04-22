import SwiftUI

enum SettingsSection: String, CaseIterable, Hashable {
    case me
    case stats
    case recentForm
    case appearance
    case data
    case about

    var title: String {
        switch self {
        case .me: return "Me"
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
        case .stats: return "chart.bar.fill"
        case .recentForm: return "waveform.path.ecg"
        case .appearance: return "paintbrush.fill"
        case .data: return "icloud.and.arrow.down.fill"
        case .about: return "info.circle.fill"
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    header
                    sectionList
                }
                .padding(.horizontal, Layout.pagePadding)
                .padding(.top, 8)
                .padding(.bottom, 12)
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
        HStack {
            Text("Settings")
                .font(.title.bold())
                .foregroundColor(Theme.text)
            Spacer(minLength: 0)
        }
        .padding(.top, 4)
        .padding(.horizontal, 2)
    }

    private var sectionList: some View {
        VStack(spacing: 10) {
            ForEach(SettingsSection.allCases, id: \.self) { section in
                NavigationLink(value: section) {
                    SettingsSectionRow(section: section)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct SettingsSectionRow: View {
    let section: SettingsSection

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.panel2)
                    .frame(width: 38, height: 38)
                Image(systemName: section.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.purple)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(section.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.text)
                Text(section.subtitle)
                    .font(.caption2)
                    .foregroundColor(Theme.text2)
                    .lineLimit(2)
            }

            Spacer(minLength: 10)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(Theme.muted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Theme.panel)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.5))
    }
}
