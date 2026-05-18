import Foundation

enum WatchConnectivityCodec {
    static func payload(for envelope: WatchSyncEnvelope) -> [String: Any]? {
        jsonObject(from: envelope)
    }

    static func snapshot(from message: [String: Any]) -> WatchSessionSnapshot? {
        guard let action = message["action"] as? String,
              action == WatchSyncAction.sessionSnapshot.rawValue,
              let snapshotObject = message["snapshot"],
              let data = try? JSONSerialization.data(withJSONObject: snapshotObject) else {
            return nil
        }
        return try? JSONDecoder().decode(WatchSessionSnapshot.self, from: data)
    }

    private static func jsonObject<T: Encodable>(from value: T) -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(value),
              let object = try? JSONSerialization.jsonObject(with: data),
              let payload = object as? [String: Any] else {
            return nil
        }
        return payload
    }
}

extension WatchSessionSnapshot {
    func withoutActive(message: String?) -> WatchSessionSnapshot {
        WatchSessionSnapshot(
            active: nil,
            availableOpponents: availableOpponents,
            availableDrills: availableDrills,
            clearedSessionUUID: clearedSessionUUID,
            acknowledgedAtMs: acknowledgedAtMs,
            message: message
        )
    }
}
