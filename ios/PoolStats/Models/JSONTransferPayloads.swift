import Foundation

struct SessionJSON: Codable {
    var id: Int64
    var sessionUUID: String?
    var label: String
    var opponent: String
    var game: String
    var raceTo: Int?
    var type: String
    var ts: Int64
    var racks: [RackJSON]
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
}

struct RackJSON: Codable {
    var rackUUID: String?
    var result: String?
    var breaker: String
    var breakBalls: Int
    var breakFoul: Bool?
    var layout: String
    var outcome: String?
    var fouls: Int
    var badSafety: Int
    var badPosition: Int
    var patternCount: Int?
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

struct WebSessionJSON: Decodable {
    var id: Int64
    var label: String?
    var opponent: String?
    var game: String?
    var type: String?
    var ts: Int64?
    var racks: [WebRackJSON]
    var performanceRating: Int?
}

struct WebRackJSON: Decodable {
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

    private enum CodingKeys: String, CodingKey {
        case result, breaker, breakBalls, breakFoul, layout, outcome, fouls, badSafety, badPosition, patternCount, missCount, runoutFirst, breakAndRun
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case missEasy, missMed, missHard
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        result = try c.decodeIfPresent(String.self, forKey: .result)
        breaker = try c.decodeIfPresent(String.self, forKey: .breaker)
        breakBalls = try c.decodeIfPresent(Int.self, forKey: .breakBalls)
        breakFoul = try c.decodeIfPresent(Bool.self, forKey: .breakFoul)
        layout = try c.decodeIfPresent(String.self, forKey: .layout)
        outcome = try c.decodeIfPresent(String.self, forKey: .outcome)
        fouls = try c.decodeIfPresent(Int.self, forKey: .fouls)
        badSafety = try c.decodeIfPresent(Int.self, forKey: .badSafety)
        badPosition = try c.decodeIfPresent(Int.self, forKey: .badPosition)
        patternCount = try c.decodeIfPresent(Int.self, forKey: .patternCount)
        missCount = try c.decodeIfPresent(Int.self, forKey: .missCount)
        if missCount == nil {
            let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)
            let easy = try legacy.decodeIfPresent(Int.self, forKey: .missEasy) ?? 0
            let med = try legacy.decodeIfPresent(Int.self, forKey: .missMed) ?? 0
            let hard = try legacy.decodeIfPresent(Int.self, forKey: .missHard) ?? 0
            missCount = easy + med + hard
        }
        runoutFirst = try c.decodeIfPresent(Bool.self, forKey: .runoutFirst)
        breakAndRun = try c.decodeIfPresent(Bool.self, forKey: .breakAndRun)
    }
}

struct JSONTransferEnvelope: Codable {
    var format: String
    var version: Int
    var exportedAt: Int64
    var sessions: [SessionJSON]
    var goals: [Goal]? = nil
    var opponents: [OpponentProfile]? = nil
    var playerProfile: PlayerProfile? = nil
    var social: SocialProfileBackup? = nil
    var activeSession: ActiveSessionSnapshot? = nil
}

struct PoolStatsBackup: Equatable {
    var sessions: [Session]
    var goals: [Goal]?
    var opponents: [OpponentProfile]?
    var playerProfile: PlayerProfile?
    var social: SocialProfileBackup?
    var activeSession: ActiveSessionSnapshot?

    var includesSupplementalData: Bool {
        goals != nil
            || opponents != nil
            || playerProfile != nil
            || social != nil
            || activeSession != nil
    }
}

struct JSONImportPreview: Equatable {
    var sessionCount: Int
    var includesSupplementalData: Bool
}

struct SocialProfileBackup: Codable, Equatable {
    var profile: PublicPlayerProfile?
    var friends: [SocialFriend]
    var blockedPlayers: [BlockedPlayer]
    var outgoingShares: [OutgoingMatchShare]
    var incomingShares: [IncomingMatchShare]
}
