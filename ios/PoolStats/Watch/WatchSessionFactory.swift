import Foundation

enum WatchSessionFactory {
    static func matchSession(
        game: String,
        opponent: String,
        sessionUUID: String,
        date: Date
    ) -> WatchSession {
        WatchSession(
            id: 0,
            sessionUUID: sessionUUID,
            label: "",
            opponent: opponent,
            game: game,
            type: "match",
            ts: date,
            racks: [],
            durationSeconds: nil,
            performanceRating: nil,
            drillID: nil,
            drillTitle: nil,
            drillKind: nil,
            drillDifficulty: nil,
            drillBallCount: nil,
            drillPrimarySkill: nil,
            drillPrimarySkills: nil,
            drillSubskills: nil,
            drillSecondarySkills: nil,
            drillTargetType: nil,
            drillTargetCount: nil
        )
    }

    static func drillPracticeSession(
        drill: WatchDrillTemplatePayload,
        difficulty: WatchDrillTemplateDifficultyPayload,
        targetType: String,
        targetCount: Int,
        sessionUUID: String,
        date: Date
    ) -> WatchSession {
        WatchSession(
            id: 0,
            sessionUUID: sessionUUID,
            label: drill.title,
            opponent: "",
            game: "8ball",
            type: "practice",
            ts: date,
            racks: [],
            durationSeconds: nil,
            performanceRating: nil,
            drillID: drill.id,
            drillTitle: drill.title,
            drillKind: nil,
            drillDifficulty: difficulty.level,
            drillBallCount: difficulty.ballCount,
            drillPrimarySkill: nil,
            drillPrimarySkills: nil,
            drillSubskills: nil,
            drillSecondarySkills: nil,
            drillTargetType: targetType,
            drillTargetCount: targetCount
        )
    }

    static func freshRack(index: Int) -> WatchRack {
        WatchRack(
            id: UUID().uuidString,
            rackUUID: UUID().uuidString,
            index: index,
            result: nil,
            breaker: "none",
            breakBalls: -1,
            breakFoul: false,
            layout: "open",
            outcome: nil,
            fouls: 0,
            badSafety: 0,
            badPosition: 0,
            patternCount: 0,
            missCount: 0,
            runoutFirst: false,
            breakAndRun: false,
            drillOutcome: nil,
            drillTags: nil,
            drillNotes: nil,
            drillBallsMade: nil,
            drillTargetBallCount: nil,
            drillDifficulty: nil
        )
    }

    static func drillAttemptRack(index: Int, attempt: WatchDrillAttemptPayload) -> WatchRack {
        WatchRack(
            id: UUID().uuidString,
            rackUUID: UUID().uuidString,
            index: index,
            result: nil,
            breaker: "none",
            breakBalls: -1,
            breakFoul: false,
            layout: "none",
            outcome: nil,
            fouls: 0,
            badSafety: 0,
            badPosition: 0,
            patternCount: 0,
            missCount: 0,
            runoutFirst: false,
            breakAndRun: false,
            drillOutcome: attempt.outcome,
            drillTags: attempt.tags.isEmpty ? nil : attempt.tags,
            drillNotes: nil,
            drillBallsMade: attempt.ballsMade,
            drillTargetBallCount: attempt.targetBallCount,
            drillDifficulty: attempt.difficulty
        )
    }
}
