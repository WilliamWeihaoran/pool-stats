import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    VStack(spacing: 2) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .imageScale(.small)
                        Text("Dashboard")
                            .font(.caption2)
                    }
                }
            LogView()
                .tabItem {
                    VStack(spacing: 2) {
                        Image(systemName: "plus.circle")
                            .imageScale(.small)
                        Text("Log")
                            .font(.caption2)
                    }
                }
            HistoryView()
                .tabItem {
                    VStack(spacing: 2) {
                        Image(systemName: "clock.arrow.circlepath")
                            .imageScale(.small)
                        Text("History")
                            .font(.caption2)
                    }
                }
        }
        .tint(Theme.purple)
        .preferredColorScheme(.dark)
    }
}
