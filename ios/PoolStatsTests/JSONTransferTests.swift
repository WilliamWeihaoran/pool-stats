import XCTest
@testable import PoolStats

final class JSONTransferTests: XCTestCase {
    func testExportWrapsSessionsInVersionedEnvelope() throws {
        let sessions = [
            makeSession(
                id: 5,
                ts: Date(timeIntervalSince1970: 1_700_000_000),
                racks: [makeRack(index: 1, result: "won")]
            )
        ]

        let exported = try JSONTransfer.exportSessions(sessions)
        let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: exported) as? [String: Any])
        let sessionPayload = try XCTUnwrap(root["sessions"] as? [[String: Any]])

        XCTAssertEqual(root["format"] as? String, "pool-stats-export")
        XCTAssertEqual(root["version"] as? Int, 2)
        XCTAssertEqual(sessionPayload.count, 1)
        XCTAssertEqual(sessionPayload.first?["id"] as? Int64, 5)
    }

    func testRoundTripExportAndImportPreservesCoreSessionData() throws {
        let original = [
            makeSession(
                id: 42,
                ts: Date(timeIntervalSince1970: 1_700_100_000),
                racks: [
                    makeRack(index: 1, result: "won", breaker: "me", breakBalls: 2, outcome: "runout", fouls: 1, badPosition: 2, missCount: 3, runoutFirst: true, breakAndRun: true),
                    makeRack(index: 2, result: "lost", breaker: "opp", breakBalls: 0, outcome: "error", fouls: 0, badSafety: 1, missCount: 1)
                ],
                game: "9ball",
                type: "match",
                performanceRating: 8
            )
        ]

        let exported = try JSONTransfer.exportSessions(original)
        let imported = try JSONTransfer.importSessions(exported)

        let session = try XCTUnwrap(imported.first)
        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(session.id, 42)
        XCTAssertEqual(session.sessionUUID, "session-42")
        XCTAssertEqual(session.game, "9ball")
        XCTAssertEqual(session.type, "match")
        XCTAssertEqual(session.performanceRating, 8)
        XCTAssertEqual(session.racks.count, 2)
        XCTAssertEqual(session.racks[0].index, 1)
        XCTAssertEqual(session.racks[0].outcome, "runout")
        XCTAssertEqual(session.racks[1].index, 2)
        XCTAssertEqual(session.racks[1].result, "lost")
    }

    func testPreviewImportCountSupportsVersionedEnvelope() throws {
        let sessions = [
            makeSession(id: 1, ts: Date(timeIntervalSince1970: 1_700_000_000), racks: [makeRack(index: 1)]),
            makeSession(id: 2, ts: Date(timeIntervalSince1970: 1_700_000_100), racks: [makeRack(index: 1)])
        ]

        let exported = try JSONTransfer.exportSessions(sessions)
        let previewCount = try JSONTransfer.previewImportCount(exported)

        XCTAssertEqual(previewCount, 2)
    }

    func testImportRejectsEmptyFiles() {
        XCTAssertThrowsError(try JSONTransfer.importSessions(Data())) { error in
            XCTAssertEqual(error.localizedDescription, JSONTransfer.TransferError.emptyFile.localizedDescription)
        }
    }

    func testImportNormalizesDuplicateIdentifiersAndInvalidValues() throws {
        let json = """
        [
          {
            "id": 7,
            "sessionUUID": "dup-session",
            "label": "  League  ",
            "opponent": "  Alex  ",
            "game": "10ball",
            "type": "tournament",
            "ts": 1700000000000,
            "performanceRating": 99,
            "racks": [
              {
                "rackUUID": "dup-rack",
                "result": "won",
                "breaker": "ghost",
                "breakBalls": -2,
                "layout": "wild",
                "outcome": "mystery",
                "fouls": -1,
                "badSafety": -3,
                "badPosition": -4,
                "patternCount": -5,
                "missCount": -6,
                "runoutFirst": true,
                "breakAndRun": false
              }
            ]
          },
          {
            "id": 7,
            "sessionUUID": "dup-session",
            "label": "",
            "opponent": "",
            "game": "8ball",
            "type": "match",
            "ts": 1700000001000,
            "racks": []
          }
        ]
        """

        let imported = try JSONTransfer.importSessions(Data(json.utf8))

        XCTAssertEqual(imported.count, 2)
        XCTAssertNotEqual(imported[0].sessionUUID, imported[1].sessionUUID)
        XCTAssertNotEqual(imported[0].id, imported[1].id)
        XCTAssertEqual(imported[0].label, "League")
        XCTAssertEqual(imported[0].opponent, "Alex")
        XCTAssertEqual(imported[0].game, "8ball")
        XCTAssertEqual(imported[0].type, "match")
        XCTAssertEqual(imported[0].performanceRating, 10)

        let rack = try XCTUnwrap(imported[0].racks.first)
        XCTAssertEqual(rack.breaker, "me")
        XCTAssertEqual(rack.breakBalls, 0)
        XCTAssertEqual(rack.layout, "open")
        XCTAssertNil(rack.outcome)
        XCTAssertEqual(rack.fouls, 0)
        XCTAssertEqual(rack.badSafety, 0)
        XCTAssertEqual(rack.badPosition, 0)
        XCTAssertEqual(rack.patternCount, 0)
        XCTAssertEqual(rack.missCount, 0)
    }

    func testImportRejectsEnvelopeWithoutSessions() {
        let json = """
        {
          "format": "pool-stats-export",
          "version": 2,
          "exportedAt": 1700000000000,
          "sessions": []
        }
        """

        XCTAssertThrowsError(try JSONTransfer.importSessions(Data(json.utf8))) { error in
            XCTAssertEqual(error.localizedDescription, JSONTransfer.TransferError.noSessions.localizedDescription)
        }
    }

    func testLegacyNativeImportCanBeReexportedAndReimported() throws {
        let legacyNative = """
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

        let importedLegacy = try JSONTransfer.importSessions(Data(legacyNative.utf8))
        let exported = try JSONTransfer.exportSessions(importedLegacy)
        let reimported = try JSONTransfer.importSessions(exported)

        XCTAssertEqual(reimported.count, 1)
        XCTAssertEqual(reimported.first?.id, 101)
        XCTAssertEqual(reimported.first?.game, "9ball")
        XCTAssertEqual(reimported.first?.racks.first?.outcome, "runout")
    }
}
