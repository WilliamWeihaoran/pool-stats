import XCTest
@testable import PoolStats

final class GoalMetricTests: XCTestCase {
    func testConversionRateUsesOnlyOpenLayouts() {
        let session = makeSession(
            id: 1,
            ts: Date(timeIntervalSince1970: 1_000),
            racks: [
                makeRack(index: 1, result: "won", layout: "open", outcome: "runout"),
                makeRack(index: 2, result: "won", layout: "clustered", outcome: "runout"),
                makeRack(index: 3, result: "lost", layout: "open", outcome: "noRunout"),
            ]
        )

        let value = GoalMetric.conversionRate.value(from: [session])

        XCTAssertEqual(value, 50, accuracy: 0.001)
    }

    func testPositionalErrorsAveragePerRackIncludesFouls() {
        let session = makeSession(
            id: 2,
            ts: Date(timeIntervalSince1970: 2_000),
            racks: [
                makeRack(index: 1, fouls: 1, badPosition: 2),
                makeRack(index: 2, fouls: 2, badPosition: 0),
            ]
        )

        let value = GoalMetric.positionalErrors.value(from: [session], style: .average, basis: .racks)

        XCTAssertEqual(value, 2.5, accuracy: 0.001)
    }

    func testUnsupportedMetricForcesCumulativeGoalStyle() {
        let goal = Goal(
            title: "Raise conversion",
            metric: .conversionRate,
            target: 60,
            window: .rolling(.init(amount: 10, unit: .sessions)),
            valueStyle: .average,
            averageBasis: .sessions
        )

        XCTAssertEqual(goal.valueStyle, .cumulative)
        XCTAssertEqual(goal.averageBasis, .racks)
    }

    func testPracticeScopedGoalCurrentValueFiltersOutMatches() {
        let practice = makeSession(
            id: 3,
            ts: Date(timeIntervalSince1970: 3_000),
            racks: [makeRack(index: 1, missCount: 1), makeRack(index: 2, missCount: 3)],
            type: "practice"
        )
        let match = makeSession(
            id: 4,
            ts: Date(timeIntervalSince1970: 4_000),
            racks: [makeRack(index: 1, missCount: 50)],
            type: "match"
        )
        let goal = Goal(
            title: "Keep misses low",
            metric: .missErrors,
            target: 2,
            window: .rolling(.init(amount: 10, unit: .sessions)),
            valueStyle: .average,
            averageBasis: .racks,
            sessionScope: .practice,
            createdAt: Date(timeIntervalSince1970: 0)
        )

        let value = goal.currentValue(from: [practice, match])

        XCTAssertEqual(value, 2, accuracy: 0.001)
    }
}
