import SwiftUI

enum AppTab: String, CaseIterable, Hashable {
    case dashboard, log, history, goals, settings

    var label: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .log: return "Log"
        case .history: return "History"
        case .goals: return "Goals"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "chart.line.uptrend.xyaxis"
        case .log: return "plus.circle"
        case .history: return "clock.arrow.circlepath"
        case .goals: return "target"
        case .settings: return "gearshape"
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        ZStack {
            currentContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppTabBar(selection: $selectedTab)
        }
        .background(Theme.bg.ignoresSafeArea())
        .preferredColorScheme(themeStore.selectedTheme.scheme)
    }

    @ViewBuilder
    private var currentContent: some View {
        switch selectedTab {
        case .dashboard:
            DashboardView()
        case .log:
            LogView()
        case .history:
            NavigationStack { HistoryView() }
        case .goals:
            GoalsView()
        case .settings:
            SettingsView()
        }
    }
}
