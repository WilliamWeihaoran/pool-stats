import XCTest
@testable import PoolStats

final class DrillSessionTests: XCTestCase {
    func testStandardDifficultyPrefersStandardLevel() {
        let template = DrillTemplate(
            id: "cut-shot",
            title: "Cut shot",
            kind: .staticLayout,
            pictureID: "cut",
            description: "Pocket the object ball.",
            primarySkills: ["Potting"],
            secondarySkills: ["Cue ball control"],
            countUnit: .shots,
            difficultyLevels: [
                DrillDifficulty(level: .easy, ballCount: 2, constraint: ""),
                DrillDifficulty(level: .standard, ballCount: 4, constraint: ""),
                DrillDifficulty(level: .hard, ballCount: 6, constraint: ""),
            ],
            instructions: ["Shoot the layout."]
        )

        XCTAssertEqual(template.standardDifficulty.level, .standard)
        XCTAssertEqual(template.standardDifficulty.ballCount, 4)
    }

    func testDifficultyRangeTextUsesCountUnitRange() {
        let template = DrillTemplate(
            id: "break-practice",
            title: "Break practice",
            kind: .randomLayout,
            pictureID: "break",
            description: "Work on your break.",
            primarySkills: ["Break"],
            secondarySkills: ["Power"],
            countUnit: .breaks,
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 2, constraint: ""),
                DrillDifficulty(level: .expert, ballCount: 5, constraint: ""),
            ],
            instructions: ["Break and note the spread."]
        )

        XCTAssertEqual(template.difficultyRangeText, "2-5 breaks")
        XCTAssertEqual(template.difficultySummary(template.standardDifficulty), "Beginner · 2 breaks")
    }

    func testDrillSessionComputesAttemptsSuccessRateAndSuccessProgress() {
        let session = makeSession(
            id: 10,
            ts: Date(timeIntervalSince1970: 1_000),
            racks: [
                makeRack(index: 1, drillOutcome: "success", drillBallsMade: 3, drillTargetBallCount: 3),
                makeRack(index: 2, drillOutcome: "miss", drillBallsMade: 1, drillTargetBallCount: 3),
                makeRack(index: 3, drillOutcome: "success", drillBallsMade: 3, drillTargetBallCount: 3),
                makeRack(index: 4),
            ],
            type: "practice",
            drillID: "line-up",
            drillTitle: "Line-up",
            drillDifficulty: DrillDifficultyLevel.standard.rawValue,
            drillBallCount: 3,
            drillTargetType: "successes",
            drillTargetCount: 3
        )

        XCTAssertEqual(session.drillAttempts, 3)
        XCTAssertEqual(session.drillSuccesses, 2)
        XCTAssertEqual(session.drillMisses, 1)
        XCTAssertEqual(session.drillSuccessRate, 67)
        XCTAssertEqual(session.drillTargetProgress?.current, 2)
        XCTAssertEqual(session.drillTargetProgress?.target, 3)
    }

    func testDrillSessionUsesAttemptBasedProgressWhenRequested() {
        let session = makeSession(
            id: 11,
            ts: Date(timeIntervalSince1970: 2_000),
            racks: [
                makeRack(index: 1, drillOutcome: "success"),
                makeRack(index: 2, drillOutcome: "miss"),
                makeRack(index: 3, drillOutcome: "miss"),
            ],
            type: "practice",
            drillID: "speed-control",
            drillTitle: "Speed control",
            drillDifficulty: DrillDifficultyLevel.easy.rawValue,
            drillBallCount: 2,
            drillTargetType: "attempts",
            drillTargetCount: 4
        )

        XCTAssertEqual(session.drillTargetProgress?.current, 3)
        XCTAssertEqual(session.drillTargetLabel, "Target: 4 attempts")
    }
}
