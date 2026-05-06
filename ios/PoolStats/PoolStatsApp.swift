import SwiftUI

@main
struct PoolStatsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = DataStore()
    @StateObject private var logStore = SessionLogStore()
    @StateObject private var themeStore = ThemeStore()
    @StateObject private var goalsStore = GoalsStore()
    @StateObject private var opponentStore = OpponentStore()
    @StateObject private var authStore = AuthStore()
    @StateObject private var profileStore = PlayerProfileStore()
    @StateObject private var socialProfileStore = SocialProfileStore()
    @StateObject private var watchSyncStore = WatchSyncStore()

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
                .environmentObject(socialProfileStore)
                .environmentObject(watchSyncStore)
                .task {
                    watchSyncStore.bind(dataStore: store, logStore: logStore, opponentStore: opponentStore)
                }
                .onChange(of: scenePhase) { newPhase in
                    guard newPhase == .active else { return }
                    Task { await authStore.refreshCredentialState() }
                }
        }
    }
}
