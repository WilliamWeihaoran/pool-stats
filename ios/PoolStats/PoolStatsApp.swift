import SwiftUI

@main
struct PoolStatsApp: App {
    @StateObject private var store = DataStore()
    @StateObject private var logStore = SessionLogStore()
    @StateObject private var themeStore = ThemeStore()
    @StateObject private var goalsStore = GoalsStore()
    @StateObject private var opponentStore = OpponentStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(logStore)
                .environmentObject(themeStore)
                .environmentObject(goalsStore)
                .environmentObject(opponentStore)
        }
    }
}
