import Foundation

struct Rack: Identifiable, Codable, Hashable {
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

    var converted: Bool { outcome == "runout" }
    var isNoRunout: Bool { outcome == "noRunout" }
    var positionalCount: Int { badPosition }
    var positionTrackingCount: Int { badPosition + fouls }
    var safetyCount: Int { badSafety }
    var patternMistakeCount: Int { patternCount }
    var foulCount: Int { fouls }
    var unforcedErrorCount: Int { missCount + positionTrackingCount + safetyCount }
    var isDrillAttempt: Bool { drillOutcome != nil }
    var drillOutcomeLabel: String {
        switch drillOutcome {
        case "success": return NSLocalizedString("Success", comment: "")
        case "miss": return NSLocalizedString("Miss", comment: "")
        default: return NSLocalizedString("Attempt", comment: "")
        }
    }

    init(
        id: String = UUID().uuidString,
        rackUUID: String = UUID().uuidString,
        index: Int,
        result: String? = nil,
        breaker: String = "none",
        breakBalls: Int = -1,
        breakFoul: Bool = false,
        layout: String = "none",
        outcome: String? = nil,
        fouls: Int = 0,
        badSafety: Int = 0,
        badPosition: Int = 0,
        patternCount: Int = 0,
        missCount: Int = 0,
        runoutFirst: Bool = false,
        breakAndRun: Bool = false,
        drillOutcome: String? = nil,
        drillTags: [String]? = nil,
        drillNotes: String? = nil,
        drillBallsMade: Int? = nil,
        drillTargetBallCount: Int? = nil,
        drillDifficulty: String? = nil
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

    enum CodingKeys: String, CodingKey {
        case id
        case rackUUID
        case index
        case result
        case breaker
        case breakBalls
        case breakFoul
        case layout
        case outcome
        case fouls
        case badSafety
        case badPosition
        case patternCount
        case missCount
        case runoutFirst
        case breakAndRun
        case drillOutcome
        case drillTags
        case drillNotes
        case drillBallsMade
        case drillTargetBallCount
        case drillDifficulty
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        rackUUID = try c.decodeIfPresent(String.self, forKey: .rackUUID) ?? "rack-\(id)"
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

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(rackUUID, forKey: .rackUUID)
        try c.encode(index, forKey: .index)
        try c.encodeIfPresent(result, forKey: .result)
        try c.encode(breaker, forKey: .breaker)
        try c.encode(breakBalls, forKey: .breakBalls)
        try c.encode(breakFoul, forKey: .breakFoul)
        try c.encode(layout, forKey: .layout)
        try c.encodeIfPresent(outcome, forKey: .outcome)
        try c.encode(fouls, forKey: .fouls)
        try c.encode(badSafety, forKey: .badSafety)
        try c.encode(badPosition, forKey: .badPosition)
        try c.encode(patternCount, forKey: .patternCount)
        try c.encode(missCount, forKey: .missCount)
        try c.encode(runoutFirst, forKey: .runoutFirst)
        try c.encode(breakAndRun, forKey: .breakAndRun)
        try c.encodeIfPresent(drillOutcome, forKey: .drillOutcome)
        if let drillTags, !drillTags.isEmpty { try c.encode(drillTags, forKey: .drillTags) }
        try c.encodeIfPresent(drillNotes, forKey: .drillNotes)
        try c.encodeIfPresent(drillBallsMade, forKey: .drillBallsMade)
        try c.encodeIfPresent(drillTargetBallCount, forKey: .drillTargetBallCount)
        try c.encodeIfPresent(drillDifficulty, forKey: .drillDifficulty)
    }
}
