import SwiftUI

@main
struct PoolStatsApp: App {
    @StateObject private var store = DataStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
