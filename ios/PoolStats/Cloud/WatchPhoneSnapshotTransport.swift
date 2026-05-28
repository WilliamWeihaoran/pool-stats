import Foundation
import WatchConnectivity

enum WatchPhoneSnapshotTransport {
    static func payload(for snapshot: WatchSessionSnapshot) -> [String: Any]? {
        jsonObject(from: snapshot)
    }

    static func envelope(from message: [String: Any]) -> WatchSyncEnvelope? {
        guard let data = try? JSONSerialization.data(withJSONObject: message) else {
            return nil
        }
        return try? JSONDecoder().decode(WatchSyncEnvelope.self, from: data)
    }

    static func snapshotMessage(payload: [String: Any]) -> [String: Any] {
        ["action": WatchSyncAction.sessionSnapshot.rawValue, "snapshot": payload]
    }

    static func isSnapshotMessage(_ message: [String: Any]) -> Bool {
        (message["action"] as? String) == WatchSyncAction.sessionSnapshot.rawValue
    }

    static func sendSnapshot(payload: [String: Any], using session: WCSession) {
        guard session.activationState == .activated else { return }
        #if os(iOS)
        guard session.isPaired, session.isWatchAppInstalled else { return }
        #endif

        let message = snapshotMessage(payload: payload)
        try? session.updateApplicationContext(message)
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
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
