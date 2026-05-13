import Foundation

enum FriendMatchSharing {
    static func makeOutgoingShare(
        session: Session,
        friend: SocialFriend,
        sender: PublicPlayerProfile,
        inviteUUID: String = UUID().uuidString,
        createdAt: Date = Date()
    ) throws -> OutgoingMatchShare {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(session)
        guard let json = String(data: data, encoding: .utf8) else {
            throw SocialProfileError.couldNotEncodeMatch
        }

        return OutgoingMatchShare(
            inviteUUID: inviteUUID,
            recordName: nil,
            senderFriendCode: sender.friendCode,
            senderDisplayName: sender.displayName,
            recipientFriendCode: SocialProfileStore.normalizeFriendCode(friend.friendCode),
            recipientDisplayName: friend.displayName,
            recipientOwnerRecordName: friend.ownerRecordName,
            sessionUUID: session.sessionUUID,
            sessionJSON: json,
            sessionLabel: session.displayLabel,
            game: session.game,
            type: session.type,
            opponent: session.opponent,
            wins: session.wins,
            losses: session.losses,
            createdAt: createdAt,
            status: "pending",
            failureMessage: nil
        )
    }

    static func acceptedSession(from share: IncomingMatchShare) throws -> Session {
        guard let data = share.sessionJSON.data(using: .utf8) else {
            throw SocialProfileError.couldNotDecodeMatch
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let original = try decoder.decode(Session.self, from: data)
        return mirroredSession(original, from: share)
    }

    static func mirroredSession(_ original: Session, from share: IncomingMatchShare) -> Session {
        let mirroredRacks = original.racks.map { rack in
            var mirrored = rack
            mirrored.result = mirroredResult(rack.result)
            mirrored.breaker = mirroredBreaker(rack.breaker)
            // Keep the logged rack detail intact and only flip the fields that are
            // explicitly player-relative for the receiving side.
            mirrored.breakAndRun = mirrored.runoutFirst && mirrored.breaker == "me" && mirrored.breakBalls >= 1
            return mirrored
        }

        return Session(
            id: stableSharedSessionID(for: share.inviteUUID),
            sessionUUID: "shared-\(share.inviteUUID)",
            label: original.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Shared match" : original.label,
            opponent: share.senderDisplayName,
            game: original.game,
            type: original.type,
            ts: original.ts,
            racks: mirroredRacks,
            durationSeconds: original.durationSeconds,
            performanceRating: nil
        )
    }

    static func mirroredResult(_ result: String?) -> String? {
        switch result {
        case "won": return "lost"
        case "lost": return "won"
        default: return result
        }
    }

    static func mirroredBreaker(_ breaker: String) -> String {
        switch breaker {
        case "me": return "opp"
        case "opp": return "me"
        default: return breaker
        }
    }

    static func stableSharedSessionID(for inviteUUID: String) -> Int64 {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in inviteUUID.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        let stable = hash & 0x7FFF_FFFF_FFFF_FFFF
        return Int64(stable == 0 ? 1 : stable)
    }
}
