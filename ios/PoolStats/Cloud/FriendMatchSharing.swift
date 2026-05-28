import Foundation

enum FriendMatchSharing {
    struct SharedMatchPayload: Codable, Equatable {
        var version: Int = 1
        var sessionUUID: String
        var sessionLabel: String
        var game: String
        var type: String
        var ts: Date
        var durationSeconds: Int?
        var racks: [SharedRackPayload]
    }

    struct SharedRackPayload: Codable, Equatable {
        var index: Int
        var result: String?
        var breaker: String
        var breakBalls: Int
        var breakFoul: Bool
        var layout: String
        var outcome: String?
        var fouls: Int
        var badSafety: Int
        var badPosition: Int
        var patternCount: Int
        var missCount: Int
        var runoutFirst: Bool
        var breakAndRun: Bool
    }

    static func makeOutgoingShare(
        session: Session,
        friend: SocialFriend,
        sender: PublicPlayerProfile,
        inviteUUID: String = UUID().uuidString,
        createdAt: Date = Date()
    ) throws -> OutgoingMatchShare {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let payload = sharedPayload(from: session)
        let data = try encoder.encode(payload)
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
            sessionLabel: sharedSessionLabel(for: session),
            game: session.game,
            type: session.type,
            opponent: "",
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
        if let payload = try? decoder.decode(SharedMatchPayload.self, from: data) {
            return mirroredSession(payload, from: share)
        }

        let legacyOriginal = try decoder.decode(Session.self, from: data)
        return mirroredSession(legacyOriginal, from: share)
    }

    static func sharedPayload(from session: Session) -> SharedMatchPayload {
        SharedMatchPayload(
            sessionUUID: session.sessionUUID,
            sessionLabel: sharedSessionLabel(for: session),
            game: session.game,
            type: session.type,
            ts: session.ts,
            durationSeconds: session.durationSeconds,
            racks: session.racks.map { rack in
                SharedRackPayload(
                    index: rack.index,
                    result: rack.result,
                    breaker: rack.breaker,
                    breakBalls: rack.breakBalls,
                    breakFoul: rack.breakFoul,
                    layout: rack.layout,
                    outcome: rack.outcome,
                    fouls: rack.fouls,
                    badSafety: rack.badSafety,
                    badPosition: rack.badPosition,
                    patternCount: rack.patternCount,
                    missCount: rack.missCount,
                    runoutFirst: rack.runoutFirst,
                    breakAndRun: rack.breakAndRun
                )
            }
        )
    }

    private static func sharedSessionLabel(for session: Session) -> String {
        let gameName = session.game == "9ball" ? "9 ball" : "8 ball"
        return "\(gameName) match"
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

    static func mirroredSession(_ payload: SharedMatchPayload, from share: IncomingMatchShare) -> Session {
        let mirroredRacks = payload.racks.map { rack in
            Rack(
                index: rack.index,
                result: mirroredResult(rack.result),
                breaker: mirroredBreaker(rack.breaker),
                breakBalls: rack.breakBalls,
                breakFoul: rack.breakFoul,
                layout: rack.layout,
                outcome: rack.outcome,
                fouls: rack.fouls,
                badSafety: rack.badSafety,
                badPosition: rack.badPosition,
                patternCount: rack.patternCount,
                missCount: rack.missCount,
                runoutFirst: rack.runoutFirst,
                breakAndRun: rack.runoutFirst && mirroredBreaker(rack.breaker) == "me" && rack.breakBalls >= 1
            )
        }

        return Session(
            id: stableSharedSessionID(for: share.inviteUUID),
            sessionUUID: "shared-\(share.inviteUUID)",
            label: payload.sessionLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Shared match" : payload.sessionLabel,
            opponent: share.senderDisplayName,
            game: payload.game,
            type: payload.type,
            ts: payload.ts,
            racks: mirroredRacks,
            durationSeconds: payload.durationSeconds,
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
