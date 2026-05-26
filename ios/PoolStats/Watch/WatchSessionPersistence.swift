import Foundation

struct WatchClosedSessionMarker: Codable, Equatable {
    var sessionUUID: String
    var closedAt: Date
}

enum WatchSessionPersistence {
    private static let activeKey = "poolstats.watch.local.session.v1"
    private static let drillsKey = "poolstats.watch.local.drills.v1"
    private static let closedSessionKey = "poolstats.watch.closed.session.v1"

    static func restoreActive() -> ActiveSessionSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: activeKey) else {
            return nil
        }
        guard let snapshot = try? JSONDecoder().decode(ActiveSessionSnapshot.self, from: data) else {
            UserDefaults.standard.removeObject(forKey: activeKey)
            WatchComplicationStateStore.clear()
            return nil
        }
        WatchComplicationStateStore.save(active: snapshot)
        return snapshot
    }

    static func saveActive(_ snapshot: ActiveSessionSnapshot?) {
        guard let snapshot else {
            clearActive(clearComplication: false)
            return
        }
        guard let data = try? JSONEncoder().encode(snapshot) else {
            return
        }
        UserDefaults.standard.set(data, forKey: activeKey)
        WatchComplicationStateStore.save(active: snapshot)
    }

    static func clearActive(clearComplication: Bool) {
        UserDefaults.standard.removeObject(forKey: activeKey)
        if clearComplication {
            WatchComplicationStateStore.clear()
        }
    }

    static func restoreDrills() -> [WatchDrillTemplatePayload] {
        guard let data = UserDefaults.standard.data(forKey: drillsKey) else {
            return []
        }
        guard let drills = try? JSONDecoder().decode([WatchDrillTemplatePayload].self, from: data) else {
            UserDefaults.standard.removeObject(forKey: drillsKey)
            return []
        }
        return drills
    }

    static func saveDrills(_ drills: [WatchDrillTemplatePayload]) {
        guard let data = try? JSONEncoder().encode(drills) else { return }
        UserDefaults.standard.set(data, forKey: drillsKey)
    }

    static func marker(sessionUUID: String?, closedAt: Date = Date()) -> WatchClosedSessionMarker? {
        guard let sessionUUID = WatchSyncReconciler.normalizedIdentifier(sessionUUID) else {
            return nil
        }
        return WatchClosedSessionMarker(sessionUUID: sessionUUID, closedAt: closedAt)
    }

    static func restoreClosedSessionMarker() -> WatchClosedSessionMarker? {
        guard let data = UserDefaults.standard.data(forKey: closedSessionKey) else {
            return nil
        }
        guard let marker = try? JSONDecoder().decode(WatchClosedSessionMarker.self, from: data) else {
            clearClosedSessionMarker()
            return nil
        }
        guard WatchSyncReconciler.shouldSuppressActiveSnapshotAfterLocalClose(
            remoteSessionUUID: marker.sessionUUID,
            locallyClosedSessionUUID: marker.sessionUUID,
            locallyClosedAt: marker.closedAt
        ) else {
            clearClosedSessionMarker()
            return nil
        }
        return marker
    }

    static func saveClosedSessionMarker(_ marker: WatchClosedSessionMarker?) {
        guard let marker,
              let data = try? JSONEncoder().encode(marker) else {
            clearClosedSessionMarker()
            return
        }
        UserDefaults.standard.set(data, forKey: closedSessionKey)
    }

    static func clearClosedSessionMarker() {
        UserDefaults.standard.removeObject(forKey: closedSessionKey)
    }
}
