import Foundation
@testable import PoolStats

func makeRack(
    index: Int,
    result: String? = nil,
    breaker: String = "me",
    breakBalls: Int = 1,
    breakFoul: Bool = false,
    layout: String = "open",
    outcome: String? = nil,
    fouls: Int = 0,
    badSafety: Int = 0,
    badPosition: Int = 0,
    patternCount: Int = 0,
    missCount: Int = 0,
    runoutFirst: Bool = false,
    breakAndRun: Bool = false,
    drillOutcome: String? = nil,
    drillBallsMade: Int? = nil,
    drillTargetBallCount: Int? = nil
) -> Rack {
    Rack(
        index: index,
        result: result,
        breaker: breaker,
        breakBalls: breakBalls,
        breakFoul: breakFoul,
        layout: layout,
        outcome: outcome,
        fouls: fouls,
        badSafety: badSafety,
        badPosition: badPosition,
        patternCount: patternCount,
        missCount: missCount,
        runoutFirst: runoutFirst,
        breakAndRun: breakAndRun,
        drillOutcome: drillOutcome,
        drillBallsMade: drillBallsMade,
        drillTargetBallCount: drillTargetBallCount
    )
}

func makeSession(
    id: Int64,
    ts: Date,
    racks: [Rack],
    game: String = "8ball",
    type: String = "match",
    performanceRating: Int? = nil,
    drillID: String? = nil,
    drillTitle: String? = nil,
    drillDifficulty: String? = nil,
    drillBallCount: Int? = nil,
    drillTargetType: String? = nil,
    drillTargetCount: Int? = nil
) -> Session {
    Session(
        id: id,
        sessionUUID: "session-\(id)",
        label: "",
        opponent: "",
        game: game,
        type: type,
        ts: ts,
        racks: racks,
        durationSeconds: nil,
        performanceRating: performanceRating,
        drillID: drillID,
        drillTitle: drillTitle,
        drillDifficulty: drillDifficulty,
        drillBallCount: drillBallCount,
        drillTargetType: drillTargetType,
        drillTargetCount: drillTargetCount
    )
}
