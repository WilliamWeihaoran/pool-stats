import XCTest
@testable import PoolStats

final class CompatibilityRegressionTests: XCTestCase {
    func testUnforcedErrorCountExcludesPatternMistakesButIncludesOtherTrackedErrors() {
        let rack = makeRack(
            index: 1,
            fouls: 1,
            badSafety: 2,
            badPosition: 3,
            patternCount: 4,
            missCount: 5
        )

        XCTAssertEqual(rack.positionTrackingCount, 4)
        XCTAssertEqual(rack.patternMistakeCount, 4)
        XCTAssertEqual(rack.unforcedErrorCount, 11)
    }

    func testNativeImportPreservesSessionMetadataAndCompatibilityIdentifiers() throws {
        let json = """
        [
          {
            "id": 101,
            "label": "League night",
            "opponent": "Alex",
            "game": "9ball",
            "raceTo": 7,
            "type": "match",
            "ts": 1700000000000,
            "durationSeconds": 3600,
            "performanceRating": 8,
            "drillPrimarySkills": ["Shotmaking"],
            "drillSubskills": ["Cue ball"],
            "drillSecondarySkills": ["Position"],
            "racks": [
              {
                "result": "won",
                "breaker": "me",
                "breakBalls": 2,
                "layout": "open",
                "outcome": "runout",
                "fouls": 1,
                "badSafety": 0,
                "badPosition": 1,
                "missCount": 2,
                "runoutFirst": true,
                "breakAndRun": true
              }
            ]
          }
        ]
        """

        let sessions = try JSONTransfer.importSessions(Data(json.utf8))
        let session = try XCTUnwrap(sessions.first)
        let rack = try XCTUnwrap(session.racks.first)

        XCTAssertEqual(session.sessionUUID, "session-101")
        XCTAssertEqual(session.durationSeconds, 3600)
        XCTAssertEqual(session.performanceRating, 8)
        XCTAssertEqual(session.raceTo, 7)
        XCTAssertEqual(session.drillPrimaryLabels, ["Shotmaking"])
        XCTAssertEqual(session.drillSecondaryLabels, ["Position"])
        XCTAssertEqual(rack.index, 1)
        XCTAssertFalse(rack.rackUUID.isEmpty)
        XCTAssertEqual(rack.patternCount, 0)
    }

    func testLegacyWebImportAggregatesMissBucketsAndAppliesCompatibilityDefaults() throws {
        let json = """
        [
          {
            "id": 202,
            "racks": [
              {
                "result": "lost",
                "badSafety": 1,
                "missEasy": 1,
                "missMed": 2,
                "missHard": 3
              }
            ],
            "performanceRating": 6
          }
        ]
        """

        let sessions = try JSONTransfer.importSessions(Data(json.utf8))
        let session = try XCTUnwrap(sessions.first)
        let rack = try XCTUnwrap(session.racks.first)

        XCTAssertEqual(session.sessionUUID, "session-202")
        XCTAssertEqual(session.label, "")
        XCTAssertEqual(session.opponent, "")
        XCTAssertEqual(session.game, "8ball")
        XCTAssertEqual(session.type, "match")
        XCTAssertNil(session.durationSeconds)
        XCTAssertEqual(session.performanceRating, 6)

        XCTAssertEqual(rack.breaker, "me")
        XCTAssertEqual(rack.breakBalls, 0)
        XCTAssertFalse(rack.breakFoul)
        XCTAssertEqual(rack.layout, "open")
        XCTAssertEqual(rack.badSafety, 1)
        XCTAssertEqual(rack.missCount, 6)
        XCTAssertFalse(rack.runoutFirst)
        XCTAssertFalse(rack.breakAndRun)
    }

    @MainActor
    func testSaveRackRejectsIncompleteMatchRack() {
        let store = SessionLogStore()

        store.startSession(game: "8ball", label: "", opponent: "", date: Date(timeIntervalSince1970: 1_700_000_000))
        store.updateRack { rack in
            rack.breaker = "me"
            rack.breakBalls = 1
            rack.result = "won"
        }

        XCTAssertFalse(store.saveRack())
        XCTAssertEqual(store.currentSession?.racks.count, 0)
        XCTAssertEqual(store.currentRack?.index, 1)
    }

    @MainActor
    func testSaveRackFromRemoteNormalizesLegacyPlaceholderValuesBeforeSaving() throws {
        let store = SessionLogStore()

        store.startSession(game: "8ball", label: "", opponent: "", date: Date(timeIntervalSince1970: 1_700_000_000))
        store.updateRack { rack in
            rack.result = "won"
            rack.breaker = "none"
            rack.breakBalls = -1
            rack.layout = "none"
            rack.outcome = nil
            rack.runoutFirst = true
        }

        XCTAssertTrue(store.saveRackFromRemote())

        let session = try XCTUnwrap(store.currentSession)
        let rack = try XCTUnwrap(session.racks.first)
        XCTAssertEqual(rack.breaker, "me")
        XCTAssertEqual(rack.breakBalls, 1)
        XCTAssertEqual(rack.layout, "open")
        XCTAssertEqual(rack.outcome, "runout")
        XCTAssertTrue(rack.breakAndRun)
    }
}
