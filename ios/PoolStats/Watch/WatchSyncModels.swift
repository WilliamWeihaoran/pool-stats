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
    case drillAttempt = "drill_attempt"
    case drillDifficulty = "drill_difficulty"
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

struct WatchDrillAttemptPayload: Codable, Hashable {
    var outcome: String
    var tags: [String]
    var ballsMade: Int
    var targetBallCount: Int
    var difficulty: String
    var saveAndExit: Bool
}

struct WatchDrillDifficultyPayload: Codable, Hashable {
    var difficulty: String
    var ballCount: Int
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
    var drillAttempt: WatchDrillAttemptPayload?
    var drillDifficulty: WatchDrillDifficultyPayload?
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
    var drillOutcome: String?
    var drillTags: [String]?
    var drillNotes: String?
    var drillBallsMade: Int?
    var drillTargetBallCount: Int?
    var drillDifficulty: String?
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
    var drillID: String?
    var drillTitle: String?
    var drillKind: String?
    var drillDifficulty: String?
    var drillBallCount: Int?
    var drillPrimarySkill: String?
    var drillPrimarySkills: [String]?
    var drillSubskills: [String]?
    var drillSecondarySkills: [String]?

    var wins: Int { racks.filter { $0.result == "won" }.count }
    var losses: Int { racks.filter { $0.result == "lost" }.count }
    var isPractice: Bool { type == "practice" }
    var isDrillPractice: Bool { isPractice && drillID != nil }
    var drillDifficultyLabel: String {
        switch drillDifficulty {
        case "beginner": return "Beginner"
        case "easy": return "Easy"
        case "standard": return "Standard"
        case "hard": return "Hard"
        case "expert": return "Expert"
        default: return "Drill"
        }
    }
}

struct ActiveSessionSnapshot: Codable, Hashable {
    var session: WatchSession
    var rack: WatchRack?
    var rackStartedAt: Date?
}


struct WatchSessionSnapshot: Codable, Hashable {
    var active: ActiveSessionSnapshot?
    var availableOpponents: [String]
    var acknowledgedAtMs: Int64
    var message: String?
}
