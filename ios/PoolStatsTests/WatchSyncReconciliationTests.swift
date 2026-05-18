import XCTest
@testable import PoolStats

final class WatchSyncReconciliationTests: XCTestCase {
    func testPhoneEndedSessionClearsMatchingWatchSession() {
        XCTAssertTrue(WatchSyncReconciler.shouldClearLocalSession(
            activeSessionUUID: "session-a",
            clearedSessionUUID: "session-a",
            message: "session_ended"
        ))
    }

    func testPhoneEndedSessionDoesNotClearDifferentWatchSession() {
        XCTAssertFalse(WatchSyncReconciler.shouldClearLocalSession(
            activeSessionUUID: "session-b",
            clearedSessionUUID: "session-a",
            message: "session_ended"
        ))
    }

    func testLegacyClearMessageStillClearsWhenNoClearMarkerExists() {
        XCTAssertTrue(WatchSyncReconciler.shouldClearLocalSession(
            activeSessionUUID: "session-a",
            clearedSessionUUID: nil,
            message: "session_discarded"
        ))
    }

    func testBlankClearMarkerDoesNotFallBackToLegacyClearMessage() {
        XCTAssertFalse(WatchSyncReconciler.shouldClearLocalSession(
            activeSessionUUID: "session-a",
            clearedSessionUUID: "   ",
            message: "session_ended"
        ))
    }

    func testWatchEndedSessionPreservesMatchingRecentComplication() {
        XCTAssertTrue(WatchSyncReconciler.shouldPreserveRecentlyEndedComplication(
            activeSessionUUID: nil,
            message: "session_ended",
            clearedSessionUUID: "session-a",
            complicationSessionUUID: "session-a",
            recentlyEndedAt: Date(timeIntervalSince1970: 1_000)
        ))
    }

    func testWatchEndedSessionDoesNotPreserveDifferentRecentComplication() {
        XCTAssertFalse(WatchSyncReconciler.shouldPreserveRecentlyEndedComplication(
            activeSessionUUID: nil,
            message: "session_ended",
            clearedSessionUUID: "session-a",
            complicationSessionUUID: "session-b",
            recentlyEndedAt: Date(timeIntervalSince1970: 1_000)
        ))
    }

    func testIdlePhoneSnapshotKeepsSameDayRecentScore() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        XCTAssertFalse(WatchSyncReconciler.shouldClearIdleComplication(
            hasActiveSession: false,
            recentlyEndedAt: now.addingTimeInterval(-600),
            complicationSessionUUID: "session-a",
            snapshotClearedSessionUUID: nil,
            now: now
        ))
    }

    func testIdlePhoneSnapshotClearsExpiredRecentScore() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        XCTAssertTrue(WatchSyncReconciler.shouldClearIdleComplication(
            hasActiveSession: false,
            recentlyEndedAt: now.addingTimeInterval(-36 * 60 * 60),
            complicationSessionUUID: "session-a",
            snapshotClearedSessionUUID: nil,
            now: now
        ))
    }

    func testRecentScoreVisibilityExpiresAcrossDays() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        XCTAssertFalse(WatchSyncReconciler.shouldShowRecentScore(
            hasActiveSession: false,
            updatedAt: now.addingTimeInterval(-36 * 60 * 60),
            recentlyEndedAt: now.addingTimeInterval(-36 * 60 * 60),
            now: now
        ))
    }

    func testRecentlyClosedLocalSessionSuppressesMatchingActiveSnapshot() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        XCTAssertTrue(WatchSyncReconciler.shouldSuppressActiveSnapshotAfterLocalClose(
            remoteSessionUUID: "session-a",
            locallyClosedSessionUUID: " session-a ",
            locallyClosedAt: now.addingTimeInterval(-60),
            now: now
        ))
    }

    func testRecentlyClosedLocalSessionDoesNotSuppressDifferentActiveSnapshot() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        XCTAssertFalse(WatchSyncReconciler.shouldSuppressActiveSnapshotAfterLocalClose(
            remoteSessionUUID: "session-b",
            locallyClosedSessionUUID: "session-a",
            locallyClosedAt: now.addingTimeInterval(-60),
            now: now
        ))
    }

    func testClosedLocalSessionSuppressionExpires() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        XCTAssertFalse(WatchSyncReconciler.shouldSuppressActiveSnapshotAfterLocalClose(
            remoteSessionUUID: "session-a",
            locallyClosedSessionUUID: "session-a",
            locallyClosedAt: now.addingTimeInterval(-WatchSyncReconciler.localCloseSuppressionWindow - 1),
            now: now
        ))
    }

    func testQueuedRackActionRequiresMatchingRackWhenRackUUIDIsPresent() {
        XCTAssertTrue(WatchSyncReconciler.acceptsRackScopedEnvelope(
            currentSessionUUID: "session-a",
            currentRackUUID: "rack-current",
            envelopeSessionUUID: "session-a",
            envelopeRackUUID: "rack-current"
        ))

        XCTAssertFalse(WatchSyncReconciler.acceptsRackScopedEnvelope(
            currentSessionUUID: "session-a",
            currentRackUUID: "rack-current",
            envelopeSessionUUID: "session-a",
            envelopeRackUUID: "rack-old"
        ))
    }

    func testQueuedRackActionRejectsStaleSession() {
        XCTAssertFalse(WatchSyncReconciler.acceptsRackScopedEnvelope(
            currentSessionUUID: "session-new",
            currentRackUUID: "rack-current",
            envelopeSessionUUID: "session-old",
            envelopeRackUUID: "rack-current"
        ))
    }

    func testLegacyRackActionWithoutRackUUIDStillUsesSessionGate() {
        XCTAssertTrue(WatchSyncReconciler.acceptsRackScopedEnvelope(
            currentSessionUUID: "session-a",
            currentRackUUID: "rack-current",
            envelopeSessionUUID: "session-a",
            envelopeRackUUID: nil
        ))

        XCTAssertFalse(WatchSyncReconciler.acceptsRackScopedEnvelope(
            currentSessionUUID: "session-b",
            currentRackUUID: "rack-current",
            envelopeSessionUUID: "session-a",
            envelopeRackUUID: nil
        ))
    }

    func testMissingSessionIdentifierRequiresCurrentSession() {
        XCTAssertTrue(WatchSyncReconciler.acceptsSessionScopedEnvelope(
            currentSessionUUID: "session-a",
            envelopeSessionUUID: nil
        ))

        XCTAssertFalse(WatchSyncReconciler.acceptsSessionScopedEnvelope(
            currentSessionUUID: nil,
            envelopeSessionUUID: nil
        ))
    }

    func testMissingRackIdentifierRequiresCurrentRack() {
        XCTAssertTrue(WatchSyncReconciler.acceptsRackScopedEnvelope(
            currentSessionUUID: "session-a",
            currentRackUUID: "rack-current",
            envelopeSessionUUID: "session-a",
            envelopeRackUUID: nil
        ))

        XCTAssertFalse(WatchSyncReconciler.acceptsRackScopedEnvelope(
            currentSessionUUID: "session-a",
            currentRackUUID: nil,
            envelopeSessionUUID: "session-a",
            envelopeRackUUID: nil
        ))
    }

    func testBlankIdentifiersAreTreatedAsMissing() {
        XCTAssertFalse(WatchSyncReconciler.acceptsSessionScopedEnvelope(
            currentSessionUUID: "session-a",
            envelopeSessionUUID: "   "
        ))

        XCTAssertFalse(WatchSyncReconciler.acceptsRackScopedEnvelope(
            currentSessionUUID: "session-a",
            currentRackUUID: "rack-current",
            envelopeSessionUUID: "session-a",
            envelopeRackUUID: "\n\t"
        ))
    }

    func testClearAndPreserveComparisonsNormalizeIdentifiers() {
        XCTAssertTrue(WatchSyncReconciler.shouldClearLocalSession(
            activeSessionUUID: " session-a ",
            clearedSessionUUID: "session-a",
            message: "session_ended"
        ))

        XCTAssertTrue(WatchSyncReconciler.shouldPreserveRecentlyEndedComplication(
            activeSessionUUID: nil,
            message: "session_ended",
            clearedSessionUUID: "session-a ",
            complicationSessionUUID: " session-a",
            recentlyEndedAt: Date(timeIntervalSince1970: 1_000)
        ))
    }

    func testDisplayedWatchBreakerDefaultsToMe() {
        XCTAssertEqual(WatchSyncReconciler.displayedBreakerValue(nil), "me")
        XCTAssertEqual(WatchSyncReconciler.displayedBreakerValue(""), "me")
        XCTAssertEqual(WatchSyncReconciler.displayedBreakerValue("me"), "me")
        XCTAssertEqual(WatchSyncReconciler.displayedBreakerValue("opp"), "opp")
    }

    func testOlderStartEnvelopeDecodesWithoutInitialRackUUID() throws {
        let json = """
        {
          "version": 1,
          "action": "start_session",
          "sessionUUID": "session-a",
          "start": {
            "game": "8-ball",
            "type": "match",
            "opponent": "Other",
            "timestampMs": 1700000000000
          },
          "sentAtMs": 1700000000000
        }
        """

        let envelope = try JSONDecoder().decode(WatchSyncEnvelope.self, from: Data(json.utf8))

        XCTAssertEqual(envelope.sessionUUID, "session-a")
        XCTAssertNil(envelope.start?.initialRackUUID)
        XCTAssertNil(envelope.rackUUID)
        XCTAssertNil(envelope.nextRackUUID)
    }

    func testSaveEnvelopeCarriesRackReplayIdentity() throws {
        let envelope = WatchSyncEnvelope(
            action: .saveRack,
            sessionUUID: "session-a",
            rackUUID: "rack-current",
            nextRackUUID: "rack-next",
            patch: nil,
            start: nil,
            end: nil,
            drillAttempt: nil,
            drillDifficulty: nil,
            sentAtMs: 1_700_000_000_000
        )

        let data = try JSONEncoder().encode(envelope)
        let decoded = try JSONDecoder().decode(WatchSyncEnvelope.self, from: data)

        XCTAssertEqual(decoded.rackUUID, "rack-current")
        XCTAssertEqual(decoded.nextRackUUID, "rack-next")
    }
}
