import Foundation

struct SessionJSON: Codable {
    var id: Int64
    var label: String
    var game: String
    var type: String
    var ts: Int64
    var racks: [RackJSON]
}

struct RackJSON: Codable {
    var result: String?
    var breaker: String
    var breakBalls: Int
    var breakFoul: Bool?
    var layout: String
    var outcome: String?
    var fouls: Int
    var badSafety: Int
    var badPosition: Int
    var planChange: Int
    var missEasy: Int
    var missMed: Int
    var missHard: Int
    var runoutFirst: Bool
    var breakAndRun: Bool
}

struct JSONTransfer {
    static func exportSessions(_ sessions: [Session]) -> Data? {
        let payload = sessions.map { s in
            SessionJSON(
                id: s.id,
                label: s.label,
                game: s.game,
                type: s.type,
                ts: Int64(s.ts.timeIntervalSince1970 * 1000),
                racks: s.racks.map { r in
                    RackJSON(
                        result: r.result,
                        breaker: r.breaker,
                        breakBalls: r.breakBalls,
                        breakFoul: r.breakFoul,
                        layout: r.layout,
                        outcome: r.outcome,
                        fouls: r.fouls,
                        badSafety: r.badSafety,
                        badPosition: r.badPosition,
                        planChange: r.planChange,
                        missEasy: r.missEasy,
                        missMed: r.missMed,
                        missHard: r.missHard,
                        runoutFirst: r.runoutFirst,
                        breakAndRun: r.breakAndRun
                    )
                }
            )
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(payload)
    }

    static func importSessions(_ data: Data) throws -> [Session] {
        let decoder = JSONDecoder()
        let payload = try decoder.decode([SessionJSON].self, from: data)
        return payload.map { s in
            let racks = s.racks.enumerated().map { idx, r in
                Rack(
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
                    planChange: r.planChange,
                    missEasy: r.missEasy,
                    missMed: r.missMed,
                    missHard: r.missHard,
                    runoutFirst: r.runoutFirst,
                    breakAndRun: r.breakAndRun
                )
            }
            return Session(
                id: s.id,
                label: s.label,
                game: s.game,
                type: s.type,
                ts: Date(timeIntervalSince1970: TimeInterval(s.ts) / 1000),
                racks: racks
            )
        }
    }
}
