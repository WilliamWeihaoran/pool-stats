import Foundation

// Shared wire models for WatchConnectivity messages.
// Keep in sync with the iOS app envelope definitions.
enum WatchSyncAction: String, Codable {
    case startSession = "start_session"
    case attachActiveSession = "attach_active_session"
    case rackPatch = "rack_patch"
    case saveRack = "save_rack"
    case undoLastRack = "undo_last_rack"
    case discardSession = "discard_session"
    case endSessionWithRating = "end_session_with_rating"
    case sessionSnapshot = "session_snapshot"
    case ack = "ack"
}

struct WatchSessionStartPayload: Codable, Hashable {
    var game: String
    var type: String
    var opponent: String
    var timestampMs: Int64?
}

struct WatchEndSessionPayload: Codable, Hashable {
    var rating: Int
}

struct WatchRackPatch: Codable, Hashable {
    var result: String?
    var breaker: String?
    var breakBalls: Int?
    var breakFoul: Bool?
    var layout: String?
    var outcome: String?
    var fouls: Int?
    var badSafety: Int?
    var badPosition: Int?
    var missCount: Int?
    var runoutFirst: Bool?
    var breakAndRun: Bool?
}

struct WatchSyncEnvelope: Codable, Hashable {
    var version: Int = 1
    var action: WatchSyncAction
    var sessionUUID: String?
    var rackUUID: String?
    var patch: WatchRackPatch?
    var start: WatchSessionStartPayload?
    var end: WatchEndSessionPayload?
    var sentAtMs: Int64
}

struct WatchRack: Codable, Hashable {
    var id: String
    var rackUUID: String
    var index: Int
    var result: String?
    var breaker: String
    var breakBalls: Int
    var breakFoul: Bool
    var layout: String
    var outcome: String?
    var fouls: Int
    var badSafety: Int
    var badPosition: Int
    var missCount: Int
    var runoutFirst: Bool
    var breakAndRun: Bool
}

struct WatchSession: Codable, Hashable {
    var id: Int64
    var sessionUUID: String
    var label: String
    var opponent: String
    var game: String
    var type: String
    var ts: Date
    var racks: [WatchRack]
    var durationSeconds: Int?
    var performanceRating: Int?

    var wins: Int { racks.filter { $0.result == "won" }.count }
    var losses: Int { racks.filter { $0.result == "lost" }.count }
    var isPractice: Bool { type == "practice" }
}

struct ActiveSessionSnapshot: Codable, Hashable {
    var session: WatchSession
    var rack: WatchRack?
}

struct WatchSessionSnapshot: Codable, Hashable {
    var active: ActiveSessionSnapshot?
    var availableOpponents: [String]
    var acknowledgedAtMs: Int64
    var message: String?
}
