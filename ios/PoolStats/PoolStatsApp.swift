import SwiftUI

@main
struct PoolStatsApp: App {
    @StateObject private var store = DataStore()
    @StateObject private var logStore = SessionLogStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(logStore)
        }
    }
}
