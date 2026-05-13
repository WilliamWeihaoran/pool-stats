import XCTest
@testable import PoolStats

final class SocialProfileStoreTests: XCTestCase {
    func testFriendCodeNormalizationAcceptsCommonInputFormats() {
        XCTAssertEqual(SocialProfileStore.normalizeFriendCode("abc123"), "PS-ABC-123")
        XCTAssertEqual(SocialProfileStore.normalizeFriendCode("ps abc 123"), "PS-ABC-123")
        XCTAssertEqual(SocialProfileStore.normalizeFriendCode("ps-abc-123"), "PS-ABC-123")
        XCTAssertTrue(SocialProfileStore.isValidFriendCode("psabc123"))
        XCTAssertFalse(SocialProfileStore.isValidFriendCode("abc12"))
    }

    func testOutgoingShareCapturesMatchMetadataAndScoreWithoutCloudKit() throws {
        let session = makeSession(
            id: 40,
            ts: Date(timeIntervalSince1970: 10_000),
            racks: [
                makeRack(index: 1, result: "won"),
                makeRack(index: 2, result: "lost"),
                makeRack(index: 3, result: "won"),
            ],
            game: "9ball",
            type: "match"
        )
        let sender = makePublicProfile(name: "William", code: "PS-ME1-234")
        let friend = makeFriend(name: "Alex", code: "abc123")
        let createdAt = Date(timeIntervalSince1970: 20_000)

        let share = try FriendMatchSharing.makeOutgoingShare(
            session: session,
            friend: friend,
            sender: sender,
            inviteUUID: "invite-1",
            createdAt: createdAt
        )

        XCTAssertEqual(share.inviteUUID, "invite-1")
        XCTAssertEqual(share.senderFriendCode, "PS-ME1-234")
        XCTAssertEqual(share.recipientFriendCode, "PS-ABC-123")
        XCTAssertEqual(share.sessionUUID, "session-40")
        XCTAssertEqual(share.sessionLabel, "9 ball match")
        XCTAssertEqual(share.game, "9ball")
        XCTAssertEqual(share.type, "match")
        XCTAssertEqual(share.wins, 2)
        XCTAssertEqual(share.losses, 1)
        XCTAssertEqual(share.status, "pending")
        XCTAssertEqual(share.createdAt, createdAt)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Session.self, from: XCTUnwrap(share.sessionJSON.data(using: .utf8)))
        XCTAssertEqual(decoded.sessionUUID, session.sessionUUID)
        XCTAssertEqual(decoded.wins, session.wins)
        XCTAssertEqual(decoded.losses, session.losses)
    }

    func testAcceptingShareMirrorsPlayerRelativeRackDataForRecipient() throws {
        let original = makeSession(
            id: 50,
            ts: Date(timeIntervalSince1970: 30_000),
            racks: [
                makeRack(index: 1, result: "won", breaker: "me", breakBalls: 2, outcome: "runout", runoutFirst: true, breakAndRun: true),
                makeRack(index: 2, result: "lost", breaker: "opp", breakBalls: 1, outcome: "runout", runoutFirst: true, breakAndRun: false),
                makeRack(index: 3, result: "won", breaker: "opp", breakBalls: 0, outcome: "noRunout", runoutFirst: false, breakAndRun: false),
            ],
            game: "8ball",
            type: "match",
            performanceRating: 8
        )
        let share = try makeIncomingShare(original: original, inviteUUID: "shared-match-1", senderName: "Alex")

        let mirrored = try FriendMatchSharing.acceptedSession(from: share)

        XCTAssertEqual(mirrored.id, FriendMatchSharing.stableSharedSessionID(for: "shared-match-1"))
        XCTAssertEqual(mirrored.sessionUUID, "shared-shared-match-1")
        XCTAssertEqual(mirrored.label, "Shared match")
        XCTAssertEqual(mirrored.opponent, "Alex")
        XCTAssertNil(mirrored.performanceRating)
        XCTAssertEqual(mirrored.racks.map(\.result), ["lost", "won", "lost"])
        XCTAssertEqual(mirrored.racks.map(\.breaker), ["opp", "me", "me"])
        XCTAssertEqual(mirrored.racks.map(\.breakAndRun), [false, true, false])
    }

    func testSharedSessionIDIsStableAndPositive() {
        let first = FriendMatchSharing.stableSharedSessionID(for: "same-invite")
        let second = FriendMatchSharing.stableSharedSessionID(for: "same-invite")
        let different = FriendMatchSharing.stableSharedSessionID(for: "different-invite")

        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first, different)
        XCTAssertGreaterThan(first, 0)
    }

    private func makePublicProfile(name: String, code: String) -> PublicPlayerProfile {
        PublicPlayerProfile(
            displayName: name,
            friendCode: SocialProfileStore.normalizeFriendCode(code),
            recordName: "PublicPlayerProfile-\(code)",
            ownerRecordName: "owner-\(code)",
            updatedAt: Date(timeIntervalSince1970: 1_000)
        )
    }

    private func makeFriend(name: String, code: String) -> SocialFriend {
        let normalized = SocialProfileStore.normalizeFriendCode(code)
        return SocialFriend(
            displayName: name,
            friendCode: normalized,
            recordName: "PublicPlayerProfile-\(normalized)",
            ownerRecordName: "owner-\(normalized)",
            addedAt: Date(timeIntervalSince1970: 2_000),
            updatedAt: Date(timeIntervalSince1970: 3_000)
        )
    }

    private func makeIncomingShare(original: Session, inviteUUID: String, senderName: String) throws -> IncomingMatchShare {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        return IncomingMatchShare(
            inviteUUID: inviteUUID,
            recordName: "FriendMatchShare-\(inviteUUID)",
            senderFriendCode: "PS-SND-123",
            senderDisplayName: senderName,
            recipientFriendCode: "PS-RCV-123",
            sessionUUID: original.sessionUUID,
            sessionJSON: json,
            sessionLabel: original.displayLabel,
            game: original.game,
            type: original.type,
            opponent: original.opponent,
            wins: original.wins,
            losses: original.losses,
            createdAt: Date(timeIntervalSince1970: 4_000),
            acceptedAt: nil,
            status: "pending",
            failureMessage: nil
        )
    }
}
