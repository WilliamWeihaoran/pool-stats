import SwiftUI

@main
struct PoolStatsWatchApp: App {
    @StateObject private var client = WatchConnectivityClient()
    @StateObject private var sessionStore = WatchSessionStore()
    @StateObject private var runtime = WatchRuntimeSession()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(client)
                .environmentObject(sessionStore)
                .environmentObject(runtime)
                .task { client.bind(to: sessionStore) }
        }
    }
}

enum LogSection: Hashable { case breakSection, layout, errors }

// MARK: - Root

private struct WatchRootView: View {
    @EnvironmentObject private var client: WatchConnectivityClient
    @EnvironmentObject private var sessionStore: WatchSessionStore
    @EnvironmentObject private var runtime: WatchRuntimeSession

    @State private var finishedSession: WatchSession?
    @State private var isReviewingFinishedSession = false
    @State private var requestedRoute: WatchLaunchRoute?
    @State private var didRestoreFinishedSession = false

    private static let finishedSessionKey = "poolstats.watch.pendingreview.v1"

    private var effectiveActive: ActiveSessionSnapshot? {
        client.snapshot?.active ?? sessionStore.activeSnapshot
    }


    var body: some View {
        NavigationStack {
            ZStack {
                if isReviewingFinishedSession, let finished = finishedSession, requestedRoute == nil {
                    WatchSessionFinishView(
                        session: finished,
                        onSave: { rating in
                            WatchComplicationStateStore.save(completed: finished)
                            client.endSession(sessionUUID: finished.sessionUUID, rating: rating)
                            isReviewingFinishedSession = false
                            finishedSession = nil
                        },
                        onDiscard: {
                            client.discardSession(sessionUUID: finished.sessionUUID)
                            isReviewingFinishedSession = false
                            finishedSession = nil
                        }
                    )
                } else if isReviewingFinishedSession {
                    Color.black
                        .ignoresSafeArea()
                } else if let active = effectiveActive, requestedRoute != .quickLog {
                    WatchActiveSessionView(active: active, onRequestFinish: { session in
                        var transaction = Transaction()
                        transaction.animation = nil
                        withTransaction(transaction) {
                            requestedRoute = nil
                            finishedSession = session
                            isReviewingFinishedSession = true
                        }
                    })
                    .id(active.session.sessionUUID)
                } else {
                    WatchSessionStartView()
                }
            }
            .onAppear {
                client.requestAttach()
                if effectiveActive != nil { runtime.start() }
                guard !didRestoreFinishedSession else { return }
                didRestoreFinishedSession = true
                if let data = UserDefaults.standard.data(forKey: Self.finishedSessionKey),
                   let session = try? JSONDecoder().decode(WatchSession.self, from: data) {
                    isReviewingFinishedSession = true
                    finishedSession = session
                }
            }
            .onOpenURL { url in handleLaunchURL(url) }
            .onChange(of: effectiveActive != nil) { _, hasSession in
                if hasSession { runtime.start() } else { runtime.stop() }
                if hasSession { requestedRoute = nil }
            }
        }
        .onChange(of: finishedSession) { _, newSession in
            if let newSession, let data = try? JSONEncoder().encode(newSession) {
                UserDefaults.standard.set(data, forKey: Self.finishedSessionKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.finishedSessionKey)
            }
        }
    }

    private func handleLaunchURL(_ url: URL) {
        guard url.scheme == "poolstatswatch",
              let host = url.host,
              let route = WatchLaunchRoute(rawValue: host) else { return }
        isReviewingFinishedSession = false
        finishedSession = nil
        switch route {
        case .quickLog:
            requestedRoute = effectiveActive == nil ? .quickLog : nil
        case .activeSession:
            requestedRoute = effectiveActive == nil ? .quickLog : .activeSession
        }
    }
}
