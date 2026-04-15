import Foundation

struct SessionJSON: Codable {
    var id: Int64
    var label: String
    var game: String
    var type: String
    var ts: Int64
    var racks: [RackJSON]
    var durationSeconds: Int?
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

struct WebSessionJSON: Codable {
    var id: Int64
    var label: String?
    var game: String?
    var type: String?
    var ts: Int64?
    var racks: [WebRackJSON]
}

struct WebRackJSON: Codable {
    var result: String?
    var breaker: String?
    var breakBalls: Int?
    var breakFoul: Bool?
    var layout: String?
    var outcome: String?
    var fouls: Int?
    var badSafety: Int?
    var badPosition: Int?
    var planChange: Int?
    var missEasy: Int?
    var missMed: Int?
    var missHard: Int?
    var runoutFirst: Bool?
    var breakAndRun: Bool?
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
                },
                durationSeconds: s.durationSeconds
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
                    racks: racks,
                    durationSeconds: s.durationSeconds
                )
            }
        }

        let web = try decoder.decode([WebSessionJSON].self, from: data)
        return web.map { s in
            let racks = s.racks.enumerated().map { idx, r in
                Rack(
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
                    planChange: r.planChange ?? 0,
                    missEasy: r.missEasy ?? 0,
                    missMed: r.missMed ?? 0,
                    missHard: r.missHard ?? 0,
                    runoutFirst: r.runoutFirst ?? false,
                    breakAndRun: r.breakAndRun ?? false
                )
            }
            let ts = s.ts.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) } ?? Date()
            return Session(
                id: s.id,
                label: s.label ?? "",
                game: s.game ?? "8ball",
                type: s.type ?? "match",
                ts: ts,
                racks: racks,
                durationSeconds: nil
            )
        }
    }
}
