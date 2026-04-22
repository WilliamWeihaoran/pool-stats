import SwiftUI

@main
struct PoolStatsApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = DataStore()
    @StateObject private var logStore = SessionLogStore()
    @StateObject private var themeStore = ThemeStore()
    @StateObject private var goalsStore = GoalsStore()
    @StateObject private var opponentStore = OpponentStore()
    @StateObject private var authStore = AuthStore()
    @StateObject private var profileStore = PlayerProfileStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(logStore)
                .environmentObject(themeStore)
                .environmentObject(goalsStore)
                .environmentObject(opponentStore)
                .environmentObject(authStore)
                .environmentObject(profileStore)
                .onChange(of: scenePhase) { newPhase in
                    guard newPhase == .active else { return }
                    Task { await authStore.refreshCredentialState() }
                }
        }
    }
}
