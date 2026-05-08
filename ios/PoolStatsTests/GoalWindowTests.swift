import XCTest
@testable import PoolStats

final class GoalWindowTests: XCTestCase {
    func testRollingRackWindowIncludesWholeSessionsUntilThreshold() {
        let newest = makeSession(
            id: 1,
            ts: Date(timeIntervalSince1970: 300),
            racks: [makeRack(index: 1), makeRack(index: 2)]
        )
        let middle = makeSession(
            id: 2,
            ts: Date(timeIntervalSince1970: 200),
            racks: [makeRack(index: 1), makeRack(index: 2)]
        )
        let oldest = makeSession(
            id: 3,
            ts: Date(timeIntervalSince1970: 100),
            racks: [makeRack(index: 1)]
        )

        let filtered = GoalWindow.rolling(.init(amount: 3, unit: .racks)).apply(to: [oldest, newest, middle])

        XCTAssertEqual(filtered.map(\.id), [1, 2])
    }

    func testDueDateWindowClampsToCreatedAtAndNow() {
        let createdAt = Date(timeIntervalSince1970: 100)
        let dueDate = Date(timeIntervalSince1970: 200)
        let now = Date(timeIntervalSince1970: 150)
        let sessions = [
            makeSession(id: 1, ts: Date(timeIntervalSince1970: 90), racks: [makeRack(index: 1)]),
            makeSession(id: 2, ts: Date(timeIntervalSince1970: 100), racks: [makeRack(index: 1)]),
            makeSession(id: 3, ts: Date(timeIntervalSince1970: 140), racks: [makeRack(index: 1)]),
            makeSession(id: 4, ts: Date(timeIntervalSince1970: 180), racks: [makeRack(index: 1)]),
        ]

        let filtered = GoalWindow.dueDate(dueDate).apply(to: sessions, createdAt: createdAt, now: now)

        XCTAssertEqual(filtered.map(\.id), [3, 2])
    }

    func testLegacyWindowDecodingMapsLastTenSessions() throws {
        let data = Data("\"last10Sessions\"".utf8)

        let decoded = try JSONDecoder().decode(GoalWindow.self, from: data)

        XCTAssertEqual(decoded, .rolling(.init(amount: 10, unit: .sessions)))
    }
}
