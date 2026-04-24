import Foundation

struct SessionJSON: Codable {
    var id: Int64
    var sessionUUID: String?
    var label: String
    var opponent: String
    var game: String
    var type: String
    var ts: Int64
    var racks: [RackJSON]
    var durationSeconds: Int?
    var performanceRating: Int?
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
    var missCount: Int
    var runoutFirst: Bool
    var breakAndRun: Bool
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
    var missCount: Int?
    var runoutFirst: Bool?
    var breakAndRun: Bool?

    private enum CodingKeys: String, CodingKey {
        case result, breaker, breakBalls, breakFoul, layout, outcome, fouls, badSafety, badPosition, missCount, runoutFirst, breakAndRun
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

    init(
        result: String? = nil,
        breaker: String? = nil,
        breakBalls: Int? = nil,
        breakFoul: Bool? = nil,
        layout: String? = nil,
        outcome: String? = nil,
        fouls: Int? = nil,
        badSafety: Int? = nil,
        badPosition: Int? = nil,
        missCount: Int? = nil,
        runoutFirst: Bool? = nil,
        breakAndRun: Bool? = nil
    ) {
        self.result = result
        self.breaker = breaker
        self.breakBalls = breakBalls
        self.breakFoul = breakFoul
        self.layout = layout
        self.outcome = outcome
        self.fouls = fouls
        self.badSafety = badSafety
        self.badPosition = badPosition
        self.missCount = missCount
        self.runoutFirst = runoutFirst
        self.breakAndRun = breakAndRun
    }
}

struct JSONTransfer {
    static func exportSessions(_ sessions: [Session]) -> Data? {
        let payload = sessions.map { s in
            SessionJSON(
                id: s.id,
                sessionUUID: s.sessionUUID,
                label: s.label,
                opponent: s.opponent,
                game: s.game,
                type: s.type,
                ts: Int64(s.ts.timeIntervalSince1970 * 1000),
                racks: s.racks.map { r in
                    RackJSON(
                        rackUUID: r.rackUUID,
                        result: r.result,
                        breaker: r.breaker,
                        breakBalls: r.breakBalls,
                        breakFoul: r.breakFoul,
                        layout: r.layout,
                        outcome: r.outcome,
                        fouls: r.fouls,
                        badSafety: r.badSafety,
                        badPosition: r.badPosition,
                        missCount: r.missCount,
                        runoutFirst: r.runoutFirst,
                        breakAndRun: r.breakAndRun
                    )
                },
                durationSeconds: s.durationSeconds,
                performanceRating: s.performanceRating
            )
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(payload)
    }

    static func importSessions(_ data: Data) throws -> [Session] {
        let decoder = JSONDecoder()
        if let payload = try? decoder.decode([SessionJSON].self, from: data) {
            return payload.map { s in
                let racks = s.racks.enumerated().map { idx, r in
                    Rack(
                        rackUUID: r.rackUUID ?? UUID().uuidString,
                        index: idx + 1,
                        result: r.result,
                        breaker: r.breaker,
                        breakBalls: r.breakBalls,
                        breakFoul: r.breakFoul ?? false,
                        layout: r.layout,
                        outcome: r.outcome,
                        fouls: r.fouls,
                        badSafety: r.badSafety,
                        badPosition: r.badPosition,
                        missCount: r.missCount,
                        runoutFirst: r.runoutFirst,
                        breakAndRun: r.breakAndRun
                    )
                }
                return Session(
                    id: s.id,
                    sessionUUID: s.sessionUUID ?? "session-\(s.id)",
                    label: s.label,
                    opponent: s.opponent,
                    game: s.game,
                    type: s.type,
                    ts: Date(timeIntervalSince1970: TimeInterval(s.ts) / 1000),
                    racks: racks,
                    durationSeconds: s.durationSeconds,
                    performanceRating: s.performanceRating
                )
            }
        }

        let web = try decoder.decode([WebSessionJSON].self, from: data)
        return web.map { s in
            let racks = s.racks.enumerated().map { idx, r in
                Rack(
                    rackUUID: UUID().uuidString,
                    index: idx + 1,
                    result: r.result,
                    breaker: r.breaker ?? "me",
                    breakBalls: r.breakBalls ?? 0,
                    breakFoul: r.breakFoul ?? false,
                    layout: r.layout ?? "open",
                    outcome: r.outcome,
                    fouls: r.fouls ?? 0,
                    badSafety: r.badSafety ?? 0,
                    badPosition: r.badPosition ?? 0,
                    missCount: r.missCount ?? 0,
                    runoutFirst: r.runoutFirst ?? false,
                    breakAndRun: r.breakAndRun ?? false
                )
            }
            let ts = s.ts.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) } ?? Date()
            return Session(
                id: s.id,
                sessionUUID: "session-\(s.id)",
                label: s.label ?? "",
                opponent: s.opponent ?? "",
                game: s.game ?? "8ball",
                type: s.type ?? "match",
                ts: ts,
                racks: racks,
                durationSeconds: nil,
                performanceRating: s.performanceRating
            )
        }
    }
}
