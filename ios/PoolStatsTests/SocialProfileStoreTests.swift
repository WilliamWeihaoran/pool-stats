import XCTest
@testable import PoolStats

@MainActor
final class SocialProfileStoreTests: XCTestCase {
    func testFriendCodeNormalizationAcceptsCommonInputFormats() {
        XCTAssertEqual(SocialProfileStore.normalizeFriendCode("abc123"), "PS-ABC-123")
        XCTAssertEqual(SocialProfileStore.normalizeFriendCode("ps abc 123"), "PS-ABC-123")
        XCTAssertEqual(SocialProfileStore.normalizeFriendCode("ps-abc-123"), "PS-ABC-123")
        XCTAssertTrue(SocialProfileStore.isValidFriendCode("psabc123"))
        XCTAssertFalse(SocialProfileStore.isValidFriendCode("abc12"))
    }

    func testOutgoingShareCapturesMatchMetadataAndScoreWithoutCloudKit() throws {
        var session = makeSession(
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
        session.label = "Private finals with Alex"
        session.opponent = "Alex"
        session.performanceRating = 10
        session.drillTitle = "Secret practice set"
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
        let decoded = try decoder.decode(FriendMatchSharing.SharedMatchPayload.self, from: XCTUnwrap(share.sessionJSON.data(using: .utf8)))
        XCTAssertEqual(decoded.sessionUUID, session.sessionUUID)
        XCTAssertEqual(decoded.racks.filter { $0.result == "won" }.count, session.wins)
        XCTAssertEqual(decoded.racks.filter { $0.result == "lost" }.count, session.losses)
        let payloadJSON = try XCTUnwrap(String(data: try JSONEncoder().encode(decoded), encoding: .utf8))
        XCTAssertFalse(payloadJSON.contains("Alex"))
        XCTAssertFalse(payloadJSON.contains("Private finals"))
        XCTAssertFalse(payloadJSON.contains("Secret practice"))
        XCTAssertFalse(payloadJSON.contains("performanceRating"))
        XCTAssertEqual(share.opponent, "")
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

    func testAcceptingCurrentSharePayloadMirrorsPlayerRelativeRackDataForRecipient() throws {
        let original = makeSession(
            id: 51,
            ts: Date(timeIntervalSince1970: 31_000),
            racks: [
                makeRack(index: 1, result: "won", breaker: "me", breakBalls: 2, outcome: "runout", runoutFirst: true, breakAndRun: true),
                makeRack(index: 2, result: "lost", breaker: "opp", breakBalls: 1, outcome: "noRunout", runoutFirst: false, breakAndRun: false),
            ],
            game: "9ball",
            type: "match",
            performanceRating: 9
        )
        let outgoing = try FriendMatchSharing.makeOutgoingShare(
            session: original,
            friend: makeFriend(name: "Recipient", code: "rcv123"),
            sender: makePublicProfile(name: "Alex", code: "snd123"),
            inviteUUID: "shared-current-1",
            createdAt: Date(timeIntervalSince1970: 32_000)
        )
        let incoming = IncomingMatchShare(
            inviteUUID: outgoing.inviteUUID,
            recordName: "FriendMatchShare-\(outgoing.inviteUUID)",
            senderFriendCode: outgoing.senderFriendCode,
            senderDisplayName: outgoing.senderDisplayName,
            recipientFriendCode: outgoing.recipientFriendCode,
            sessionUUID: outgoing.sessionUUID,
            sessionJSON: outgoing.sessionJSON,
            sessionLabel: outgoing.sessionLabel,
            game: outgoing.game,
            type: outgoing.type,
            opponent: outgoing.opponent,
            wins: outgoing.wins,
            losses: outgoing.losses,
            createdAt: outgoing.createdAt,
            acceptedAt: nil,
            status: "pending",
            failureMessage: nil
        )

        let mirrored = try FriendMatchSharing.acceptedSession(from: incoming)

        XCTAssertEqual(mirrored.game, "9ball")
        XCTAssertEqual(mirrored.opponent, "Alex")
        XCTAssertNil(mirrored.performanceRating)
        XCTAssertEqual(mirrored.racks.map(\.result), ["lost", "won"])
        XCTAssertEqual(mirrored.racks.map(\.breaker), ["opp", "me"])
    }

    func testIncomingSharesMustBeAddressedToCurrentProfile() {
        let profile = makePublicProfile(name: "Recipient", code: "rcv123")
        let share = IncomingMatchShare(
            inviteUUID: "wrong-recipient",
            recordName: nil,
            senderFriendCode: "PS-SND-123",
            senderDisplayName: "Sender",
            recipientFriendCode: "PS-OTHER1",
            sessionUUID: "session-1",
            sessionJSON: "{}",
            sessionLabel: "Shared match",
            game: "8ball",
            type: "match",
            opponent: "",
            wins: 1,
            losses: 0,
            createdAt: Date(timeIntervalSince1970: 1),
            acceptedAt: nil,
            status: "pending",
            failureMessage: nil
        )

        XCTAssertFalse(SocialProfileStore.share(share, isAddressedTo: profile))
    }

    func testSharedSessionIDIsStableAndPositive() {
        let first = FriendMatchSharing.stableSharedSessionID(for: "same-invite")
        let second = FriendMatchSharing.stableSharedSessionID(for: "same-invite")
        let different = FriendMatchSharing.stableSharedSessionID(for: "different-invite")

        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first, different)
        XCTAssertGreaterThan(first, 0)
    }

    func testDisplayNameModerationBlocksObviousProfanityAndLeetspeak() {
        XCTAssertTrue(SocialProfileStore.isAllowedPublicDisplayName("William"))
        XCTAssertFalse(SocialProfileStore.isAllowedPublicDisplayName("bad shit"))
        XCTAssertFalse(SocialProfileStore.isAllowedPublicDisplayName("f4gg0t"))
        XCTAssertFalse(SocialProfileStore.isAllowedPublicDisplayName("s.h.1.t"))
        XCTAssertFalse(SocialProfileStore.isAllowedPublicDisplayName("S h i t"))
        XCTAssertFalse(SocialProfileStore.isAllowedPublicDisplayName("   "))
    }

    func testPresentableDisplayNameRedactsUnsafeNames() {
        let store = makeIsolatedStore()

        XCTAssertEqual(store.presentableDisplayName("clean name"), "clean name")
        XCTAssertEqual(store.presentableDisplayName("sh1t talk"), "Hidden player")
    }

    func testDeleteAccountDataWithoutSavedProfileIsIdempotentSuccess() async throws {
        let store = makeIsolatedStore()

        try await store.deleteAccountData()

        XCTAssertEqual(store.accountDeletionState, .deleted)
        XCTAssertNil(store.profile)
        XCTAssertTrue(store.friends.isEmpty)
        XCTAssertTrue(store.outgoingShares.isEmpty)
        XCTAssertTrue(store.incomingShares.isEmpty)
    }

    func testHasLocalAccountDataIncludesBlockedPlayersWithoutProfile() {
        let store = makeIsolatedStore()

        XCTAssertFalse(store.hasLocalAccountData)

        store.block(friendCode: "abc123", displayName: "Blocked player")

        XCTAssertTrue(store.hasLocalAccountData)
    }

    func testHasLocalAccountDataIncludesSavedFriendsWithoutProfile() {
        let store = makeIsolatedStore()

        XCTAssertFalse(store.hasLocalAccountData)

        _ = store.addFriend(
            makePublicProfile(name: "Alex", code: "abc123")
        )

        XCTAssertTrue(store.hasLocalAccountData)
    }

    func testDeleteAccountDataWithOnlyBlockedPlayersClearsLocalAccountData() async throws {
        let store = makeIsolatedStore()
        store.block(friendCode: "abc123", displayName: "Blocked player")

        XCTAssertTrue(store.hasLocalAccountData)

        try await store.deleteAccountData()

        XCTAssertEqual(store.accountDeletionState, .deleted)
        XCTAssertFalse(store.hasLocalAccountData)
        XCTAssertTrue(store.blockedPlayers.isEmpty)
        XCTAssertNil(store.profile)
    }

    func testReplaceLocalBackupSanitizesBlockedAndDeclinedSocialData() {
        let store = makeIsolatedStore()
        let backup = SocialProfileBackup(
            profile: makePublicProfile(name: "  Me  ", code: "me1234"),
            friends: [
                makeFriend(name: "  Alex  ", code: "alx123"),
                makeFriend(name: "Alex duplicate", code: "PS-ALX-123"),
                makeFriend(name: "Blocked", code: "blk123"),
                makeFriend(name: "Invalid", code: "bad")
            ],
            blockedPlayers: [
                BlockedPlayer(displayName: "  Blocked  ", friendCode: "blk123", blockedAt: Date(timeIntervalSince1970: 10)),
                BlockedPlayer(displayName: "Self", friendCode: "me1234", blockedAt: Date(timeIntervalSince1970: 11)),
                BlockedPlayer(displayName: "Duplicate", friendCode: "PS-BLK-123", blockedAt: Date(timeIntervalSince1970: 12))
            ],
            outgoingShares: [
                makeOutgoingShare(inviteUUID: "blocked-outgoing", recipientCode: "blk123"),
                makeOutgoingShare(inviteUUID: "valid-outgoing", recipientCode: "rcv123"),
                makeOutgoingShare(inviteUUID: "valid-outgoing", recipientCode: "rcv456")
            ],
            incomingShares: [
                makeIncomingShare(inviteUUID: "blocked-incoming", senderCode: "blk123"),
                makeIncomingShare(inviteUUID: "declined-incoming", senderCode: "snd123", status: "declined"),
                makeIncomingShare(inviteUUID: "valid-incoming", senderCode: "snd123"),
                makeIncomingShare(inviteUUID: "valid-incoming", senderCode: "snd456")
            ]
        )

        store.replaceLocalBackup(backup)

        XCTAssertEqual(store.profile?.displayName, "Me")
        XCTAssertEqual(store.profile?.friendCode, "PS-ME1-234")
        XCTAssertEqual(store.friends.map(\.friendCode), ["PS-ALX-123"])
        XCTAssertEqual(store.friends.first?.displayName, "Alex")
        XCTAssertEqual(store.blockedPlayers.map(\.friendCode), ["PS-BLK-123"])
        XCTAssertEqual(store.outgoingShares.map(\.inviteUUID), ["valid-outgoing"])
        XCTAssertEqual(store.outgoingShares.first?.recipientFriendCode, "PS-RCV-123")
        XCTAssertEqual(store.incomingShares.map(\.inviteUUID), ["valid-incoming"])
        XCTAssertEqual(store.incomingShares.first?.senderFriendCode, "PS-SND-123")
    }

    func testOpponentReplaceAllDropsBlankAndDuplicateImportedProfiles() {
        let tempDir = makeTempDir()
        addTeardownBlock {
            try? FileManager.default.removeItem(at: tempDir)
        }
        let store = OpponentStore(baseDirectory: tempDir)

        store.replaceAll([
            OpponentProfile(displayName: "  Alex  ", aliases: ["A", " alex ", ""], lastSeenAt: Date(timeIntervalSince1970: 20)),
            OpponentProfile(displayName: "alex", aliases: ["Duplicate"], lastSeenAt: Date(timeIntervalSince1970: 30)),
            OpponentProfile(displayName: "  ", aliases: ["No display"], lastSeenAt: Date(timeIntervalSince1970: 40)),
            OpponentProfile(displayName: "Blair", aliases: [" A ", "B"], lastSeenAt: Date(timeIntervalSince1970: 50))
        ])

        XCTAssertEqual(store.profiles.map(\.displayName), ["Blair", "Alex"])
        XCTAssertEqual(store.profiles.first(where: { $0.displayName == "Alex" })?.aliases, ["A"])
        XCTAssertEqual(store.profiles.first(where: { $0.displayName == "Blair" })?.aliases, ["B"])
    }

    private func makeIsolatedStore() -> SocialProfileStore {
        let tempDir = makeTempDir()
        addTeardownBlock {
            try? FileManager.default.removeItem(at: tempDir)
        }
        return SocialProfileStore(baseDirectory: tempDir)
    }

    private func makeTempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
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

    private func makeOutgoingShare(inviteUUID: String, recipientCode: String, status: String = "pending") -> OutgoingMatchShare {
        let recipient = SocialProfileStore.normalizeFriendCode(recipientCode)
        return OutgoingMatchShare(
            inviteUUID: inviteUUID,
            recordName: "FriendMatchShare-\(inviteUUID)",
            senderFriendCode: "PS-ME1-234",
            senderDisplayName: "Me",
            recipientFriendCode: recipient,
            recipientDisplayName: "Recipient",
            recipientOwnerRecordName: "owner-\(recipient)",
            sessionUUID: "session-\(inviteUUID)",
            sessionJSON: "{}",
            sessionLabel: "Shared match",
            game: "8ball",
            type: "match",
            opponent: "",
            wins: 1,
            losses: 0,
            createdAt: Date(timeIntervalSince1970: 5_000),
            status: status,
            failureMessage: nil
        )
    }

    private func makeIncomingShare(inviteUUID: String, senderCode: String, status: String = "pending") -> IncomingMatchShare {
        let sender = SocialProfileStore.normalizeFriendCode(senderCode)
        return IncomingMatchShare(
            inviteUUID: inviteUUID,
            recordName: "FriendMatchShare-\(inviteUUID)",
            senderFriendCode: sender,
            senderDisplayName: "Sender",
            recipientFriendCode: "PS-ME1-234",
            sessionUUID: "session-\(inviteUUID)",
            sessionJSON: "{}",
            sessionLabel: "Shared match",
            game: "8ball",
            type: "match",
            opponent: "",
            wins: 1,
            losses: 0,
            createdAt: Date(timeIntervalSince1970: 6_000),
            acceptedAt: nil,
            status: status,
            failureMessage: nil
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
