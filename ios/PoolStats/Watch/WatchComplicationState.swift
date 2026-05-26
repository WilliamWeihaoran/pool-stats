import Foundation

#if canImport(WidgetKit)
import WidgetKit
#endif

enum WatchLaunchRoute: String {
    case quickLog = "quick-log"
    case activeSession = "active-session"
}

struct WatchComplicationSnapshot: Codable, Equatable {
    var hasActiveSession: Bool
    var sessionUUID: String?
    var game: String?
    var type: String?
    var opponent: String?
    var wins: Int
    var losses: Int
    var rackIndex: Int?
    var updatedAt: Date
    var recentlyEndedAt: Date?

    static let inactive = WatchComplicationSnapshot(
        hasActiveSession: false,
        sessionUUID: nil,
        game: nil,
        type: nil,
        opponent: nil,
        wins: 0,
        losses: 0,
        rackIndex: nil,
        updatedAt: .now,
        recentlyEndedAt: nil
    )
}

enum WatchComplicationStateStore {
    static let appGroupID = "group.com.poolstats.appi.watchshared"
    private static let snapshotKey = "poolstats.watch.complication.snapshot.v1"
    private static let fallbackURL = URL(fileURLWithPath: "/")

    static func load() -> WatchComplicationSnapshot {
        guard let data = defaults.data(forKey: snapshotKey) else {
            return .inactive
        }
        guard let decoded = try? JSONDecoder().decode(WatchComplicationSnapshot.self, from: data) else {
            defaults.removeObject(forKey: snapshotKey)
            return .inactive
        }
        return decoded
    }

    static func save(active: ActiveSessionSnapshot?) {
        let snapshot: WatchComplicationSnapshot
        if let active {
            snapshot = WatchComplicationSnapshot(
                hasActiveSession: true,
                sessionUUID: active.session.sessionUUID,
                game: active.session.game,
                type: active.session.type,
                opponent: active.session.opponent,
                wins: active.session.wins,
                losses: active.session.losses,
                rackIndex: active.rack?.index,
                updatedAt: .now,
                recentlyEndedAt: nil
            )
        } else {
            snapshot = .inactive
        }
        persist(snapshot, reload: true)
    }

    static func save(completed session: WatchSession) {
        let snapshot = WatchComplicationSnapshot(
            hasActiveSession: false,
            sessionUUID: session.sessionUUID,
            game: session.game,
            type: session.type,
            opponent: session.opponent,
            wins: session.wins,
            losses: session.losses,
            rackIndex: nil,
            updatedAt: .now,
            recentlyEndedAt: .now
        )
        persist(snapshot, reload: true)
    }

    static func clear() {
        persist(.inactive, reload: true)
    }

    static func url(for route: WatchLaunchRoute) -> URL {
        var components = URLComponents()
        components.scheme = "poolstatswatch"
        components.host = route.rawValue
        return components.url ?? fallbackURL
    }

    private static func persist(_ snapshot: WatchComplicationSnapshot, reload: Bool) {
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: snapshotKey)
        }
        guard reload else { return }
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "PoolStatsQuickLogComplication")
        WidgetCenter.shared.reloadTimelines(ofKind: "PoolStatsLiveScoreComplication")
        WidgetCenter.shared.reloadTimelines(ofKind: "PoolStatsSessionActiveComplication")
        #endif
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
}
