import SwiftUI

enum AppTab: Hashable { case dashboard, log, history }

struct RootView: View {
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @State private var selectedTab: AppTab? = .dashboard

    var body: some View {
        if hSizeClass == .regular {
            ipadLayout
        } else {
            iphoneLayout
        }
    }

    private var iphoneLayout: some View {
        TabView {
            NavigationStack { DashboardView() }
                .tabItem { Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis") }
            NavigationStack { LogView() }
                .tabItem { Label("Log", systemImage: "plus.circle") }
            NavigationStack { HistoryView() }
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
        }
        .tint(Theme.purple)
        .preferredColorScheme(.dark)
    }

    private var ipadLayout: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis").tag(AppTab.dashboard)
                Label("Log", systemImage: "plus.circle").tag(AppTab.log)
                Label("History", systemImage: "clock.arrow.circlepath").tag(AppTab.history)
            }
            .navigationTitle("Pool Stats")
        } detail: {
            NavigationStack {
                switch selectedTab {
                case .log: LogView()
                case .history: HistoryView()
                default: DashboardView()
                }
            }
        }
        .tint(Theme.purple)
        .preferredColorScheme(.dark)
    }
}
