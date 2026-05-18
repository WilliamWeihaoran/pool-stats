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
    var drillID: String? = nil
    var targetType: String? = nil
    var targetCount: Int? = nil
    var drillDifficulty: String? = nil
    var drillBallCount: Int? = nil
    var initialRackUUID: String? = nil
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

struct WatchDrillTemplateDifficultyPayload: Codable, Hashable, Identifiable {
    var level: String
    var label: String
    var ballCount: Int
    var constraint: String

    var id: String { level }
}

struct WatchDrillTemplatePayload: Codable, Hashable, Identifiable {
    var id: String
    var title: String
    var details: String
    var countUnit: String? = nil
    var difficultyLevels: [WatchDrillTemplateDifficultyPayload]

    var resolvedCountUnit: WatchDrillCountUnit {
        WatchDrillCountUnit(rawValue: countUnit ?? "") ?? .balls
    }

    func countText(_ count: Int) -> String {
        resolvedCountUnit.text(for: count)
    }

    func difficultySummary(_ difficulty: WatchDrillTemplateDifficultyPayload) -> String {
        "\(difficulty.label) · \(countText(difficulty.ballCount))"
    }
}

enum WatchDrillCountUnit: String, Codable, Hashable {
    case balls
    case shots
    case targets
    case kicks
    case banks
    case safeties
    case breaks
    case lags
    case attempts
    case reps
    case routes
    case caroms
    case jumps

    var singular: String {
        switch self {
        case .balls: return "ball"
        case .shots: return "shot"
        case .targets: return "target"
        case .kicks: return "kick"
        case .banks: return "bank"
        case .safeties: return "safety"
        case .breaks: return "break"
        case .lags: return "lag"
        case .attempts: return "attempt"
        case .reps: return "rep"
        case .routes: return "route"
        case .caroms: return "carom"
        case .jumps: return "jump"
        }
    }

    var plural: String {
        switch self {
        case .balls: return "balls"
        case .shots: return "shots"
        case .targets: return "targets"
        case .kicks: return "kicks"
        case .banks: return "banks"
        case .safeties: return "safeties"
        case .breaks: return "breaks"
        case .lags: return "lags"
        case .attempts: return "attempts"
        case .reps: return "reps"
        case .routes: return "routes"
        case .caroms: return "caroms"
        case .jumps: return "jumps"
        }
    }

    var progressTitle: String {
        switch self {
        case .balls: return "Potted"
        case .breaks: return "Breaks"
        default: return "Completed"
        }
    }

    func text(for count: Int) -> String {
        "\(count) \(count == 1 ? singular : plural)"
    }
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
    var patternCount: Int?
    var missCount: Int?
    var runoutFirst: Bool?
    var breakAndRun: Bool?
}

struct WatchSyncEnvelope: Codable, Hashable {
    var version: Int = 1
    var action: WatchSyncAction
    var sessionUUID: String?
    var rackUUID: String?
    var nextRackUUID: String?
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
    var patternCount: Int
    var missCount: Int
    var runoutFirst: Bool
    var breakAndRun: Bool
    var drillOutcome: String?
    var drillTags: [String]?
    var drillNotes: String?
    var drillBallsMade: Int?
    var drillTargetBallCount: Int?
    var drillDifficulty: String?

    init(
        id: String,
        rackUUID: String,
        index: Int,
        result: String?,
        breaker: String,
        breakBalls: Int,
        breakFoul: Bool,
        layout: String,
        outcome: String?,
        fouls: Int,
        badSafety: Int,
        badPosition: Int,
        patternCount: Int = 0,
        missCount: Int,
        runoutFirst: Bool,
        breakAndRun: Bool,
        drillOutcome: String?,
        drillTags: [String]?,
        drillNotes: String?,
        drillBallsMade: Int?,
        drillTargetBallCount: Int?,
        drillDifficulty: String?
    ) {
        self.id = id
        self.rackUUID = rackUUID
        self.index = index
        self.result = result
        self.breaker = breaker
        self.breakBalls = breakBalls
        self.breakFoul = breakFoul
        self.layout = layout
        self.outcome = outcome
        self.fouls = fouls
        self.badSafety = badSafety
        self.badPosition = badPosition
        self.patternCount = patternCount
        self.missCount = missCount
        self.runoutFirst = runoutFirst
        self.breakAndRun = breakAndRun
        self.drillOutcome = drillOutcome
        self.drillTags = drillTags
        self.drillNotes = drillNotes
        self.drillBallsMade = drillBallsMade
        self.drillTargetBallCount = drillTargetBallCount
        self.drillDifficulty = drillDifficulty
    }

    private enum CodingKeys: String, CodingKey {
        case id, rackUUID, index, result, breaker, breakBalls, breakFoul, layout, outcome
        case fouls, badSafety, badPosition, patternCount, missCount, runoutFirst, breakAndRun
        case drillOutcome, drillTags, drillNotes, drillBallsMade, drillTargetBallCount, drillDifficulty
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        rackUUID = try c.decode(String.self, forKey: .rackUUID)
        index = try c.decode(Int.self, forKey: .index)
        result = try c.decodeIfPresent(String.self, forKey: .result)
        breaker = try c.decode(String.self, forKey: .breaker)
        breakBalls = try c.decode(Int.self, forKey: .breakBalls)
        breakFoul = try c.decode(Bool.self, forKey: .breakFoul)
        layout = try c.decode(String.self, forKey: .layout)
        outcome = try c.decodeIfPresent(String.self, forKey: .outcome)
        fouls = try c.decode(Int.self, forKey: .fouls)
        badSafety = try c.decode(Int.self, forKey: .badSafety)
        badPosition = try c.decode(Int.self, forKey: .badPosition)
        patternCount = try c.decodeIfPresent(Int.self, forKey: .patternCount) ?? 0
        missCount = try c.decode(Int.self, forKey: .missCount)
        runoutFirst = try c.decode(Bool.self, forKey: .runoutFirst)
        breakAndRun = try c.decode(Bool.self, forKey: .breakAndRun)
        drillOutcome = try c.decodeIfPresent(String.self, forKey: .drillOutcome)
        drillTags = try c.decodeIfPresent([String].self, forKey: .drillTags)
        drillNotes = try c.decodeIfPresent(String.self, forKey: .drillNotes)
        drillBallsMade = try c.decodeIfPresent(Int.self, forKey: .drillBallsMade)
        drillTargetBallCount = try c.decodeIfPresent(Int.self, forKey: .drillTargetBallCount)
        drillDifficulty = try c.decodeIfPresent(String.self, forKey: .drillDifficulty)
    }
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
    var drillTargetType: String?
    var drillTargetCount: Int?

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
    var sessionStartedAt: Date?
    var rackStartedAt: Date?
}


struct WatchSessionSnapshot: Codable, Hashable {
    var active: ActiveSessionSnapshot?
    var availableOpponents: [String]
    var availableDrills: [WatchDrillTemplatePayload]? = nil
    var clearedSessionUUID: String? = nil
    var acknowledgedAtMs: Int64
    var message: String?
}
