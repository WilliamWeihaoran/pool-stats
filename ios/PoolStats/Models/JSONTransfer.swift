import Foundation

struct JSONTransfer {
    enum TransferError: LocalizedError {
        case emptyFile
        case noSessions
        case invalidPayload

        var errorDescription: String? {
            switch self {
            case .emptyFile:
                return NSLocalizedString("The selected JSON file is empty.", comment: "")
            case .noSessions:
                return NSLocalizedString("The selected JSON file does not contain any sessions to import.", comment: "")
            case .invalidPayload:
                return NSLocalizedString("The selected file is not a supported Pool Stats export.", comment: "")
            }
        }
    }

    static func exportSessions(_ sessions: [Session]) throws -> Data {
        try JSONTransferExporter.exportSessions(sessions)
    }

    static func previewImportCount(_ data: Data) throws -> Int {
        try JSONTransferImporter.previewImportCount(data)
    }

    static func importSessions(_ data: Data) throws -> [Session] {
        try JSONTransferImporter.importSessions(data)
    }
}

private enum JSONTransferExporter {
    static func exportSessions(_ sessions: [Session]) throws -> Data {
        let payload = sessions.map(sessionJSON(from:))
        let envelope = JSONTransferEnvelope(
            format: "pool-stats-export",
            version: 2,
            exportedAt: Int64(Date().timeIntervalSince1970 * 1000),
            sessions: payload
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(envelope)
    }

    private static func sessionJSON(from session: Session) -> SessionJSON {
        SessionJSON(
            id: session.id,
            sessionUUID: session.sessionUUID,
            label: session.label,
            opponent: session.opponent,
            game: session.game,
            raceTo: session.raceTo,
            type: session.type,
            ts: Int64(session.ts.timeIntervalSince1970 * 1000),
            racks: session.racks.map { rack in
                RackJSON(
                    rackUUID: rack.rackUUID,
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
                    breakAndRun: rack.breakAndRun,
                    drillOutcome: rack.drillOutcome,
                    drillTags: rack.drillTags,
                    drillNotes: rack.drillNotes,
                    drillBallsMade: rack.drillBallsMade,
                    drillTargetBallCount: rack.drillTargetBallCount,
                    drillDifficulty: rack.drillDifficulty
                )
            },
            durationSeconds: session.durationSeconds,
            performanceRating: session.performanceRating,
            drillID: session.drillID,
            drillTitle: session.drillTitle,
            drillKind: session.drillKind,
            drillDifficulty: session.drillDifficulty,
            drillBallCount: session.drillBallCount,
            drillPrimarySkill: session.drillPrimarySkill,
            drillPrimarySkills: session.drillPrimarySkills,
            drillSubskills: session.drillSubskills,
            drillSecondarySkills: session.drillSecondarySkills,
            drillTargetType: session.drillTargetType,
            drillTargetCount: session.drillTargetCount
        )
    }
}

private enum JSONTransferImporter {
    static func previewImportCount(_ data: Data) throws -> Int {
        try importSessions(data).count
    }

    static func importSessions(_ data: Data) throws -> [Session] {
        guard !trimmedJSONPayload(from: data).isEmpty else {
            throw JSONTransfer.TransferError.emptyFile
        }

        let decoder = JSONDecoder()

        if let envelope = try? decoder.decode(JSONTransferEnvelope.self, from: data) {
            return try JSONTransferNormalizer.normalizeImportedSessions(envelope.sessions.map(session(from:)))
        }

        if let payload = try? decoder.decode([SessionJSON].self, from: data) {
            return try JSONTransferNormalizer.normalizeImportedSessions(payload.map(session(from:)))
        }

        if let web = try? decoder.decode([WebSessionJSON].self, from: data) {
            return try JSONTransferNormalizer.normalizeImportedSessions(web.map(session(from:)))
        }

        throw JSONTransfer.TransferError.invalidPayload
    }

    private static func trimmedJSONPayload(from data: Data) -> Data {
        guard let string = String(data: data, encoding: .utf8) else { return data }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return Data(trimmed.utf8)
    }

    private static func session(from payload: SessionJSON) -> Session {
        let racks = payload.racks.enumerated().map { idx, rack in
            Rack(
                rackUUID: rack.rackUUID ?? UUID().uuidString,
                index: idx + 1,
                result: rack.result,
                breaker: rack.breaker,
                breakBalls: rack.breakBalls,
                breakFoul: rack.breakFoul ?? false,
                layout: rack.layout,
                outcome: rack.outcome,
                fouls: rack.fouls,
                badSafety: rack.badSafety,
                badPosition: rack.badPosition,
                patternCount: rack.patternCount ?? 0,
                missCount: rack.missCount,
                runoutFirst: rack.runoutFirst,
                breakAndRun: rack.breakAndRun,
                drillOutcome: rack.drillOutcome,
                drillTags: rack.drillTags,
                drillNotes: rack.drillNotes,
                drillBallsMade: rack.drillBallsMade,
                drillTargetBallCount: rack.drillTargetBallCount,
                drillDifficulty: rack.drillDifficulty
            )
        }

        return Session(
            id: payload.id,
            sessionUUID: payload.sessionUUID ?? "session-\(payload.id)",
            label: payload.label,
            opponent: payload.opponent,
            game: payload.game,
            raceTo: payload.raceTo,
            type: payload.type,
            ts: Date(timeIntervalSince1970: TimeInterval(payload.ts) / 1000),
            racks: racks,
            durationSeconds: payload.durationSeconds,
            performanceRating: payload.performanceRating,
            drillID: payload.drillID,
            drillTitle: payload.drillTitle,
            drillKind: payload.drillKind,
            drillDifficulty: payload.drillDifficulty,
            drillBallCount: payload.drillBallCount,
            drillPrimarySkill: payload.drillPrimarySkill,
            drillPrimarySkills: payload.drillPrimarySkills ?? [],
            drillSubskills: payload.drillSubskills ?? [],
            drillSecondarySkills: payload.drillSecondarySkills ?? [],
            drillTargetType: payload.drillTargetType,
            drillTargetCount: payload.drillTargetCount
        )
    }

    private static func session(from payload: WebSessionJSON) -> Session {
        let racks = payload.racks.enumerated().map { idx, rack in
            Rack(
                rackUUID: UUID().uuidString,
                index: idx + 1,
                result: rack.result,
                breaker: rack.breaker ?? "me",
                breakBalls: rack.breakBalls ?? 0,
                breakFoul: rack.breakFoul ?? false,
                layout: rack.layout ?? "open",
                outcome: rack.outcome,
                fouls: rack.fouls ?? 0,
                badSafety: rack.badSafety ?? 0,
                badPosition: rack.badPosition ?? 0,
                patternCount: rack.patternCount ?? 0,
                missCount: rack.missCount ?? 0,
                runoutFirst: rack.runoutFirst ?? false,
                breakAndRun: rack.breakAndRun ?? false
            )
        }
        let ts = payload.ts.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) } ?? Date()
        return Session(
            id: payload.id,
            sessionUUID: "session-\(payload.id)",
            label: payload.label ?? "",
            opponent: payload.opponent ?? "",
            game: payload.game ?? "8ball",
            type: payload.type ?? "match",
            ts: ts,
            racks: racks,
            durationSeconds: nil,
            performanceRating: payload.performanceRating
        )
    }
}

private enum JSONTransferNormalizer {
    private static let supportedGames: Set<String> = ["8ball", "9ball"]
    private static let supportedTypes: Set<String> = ["match", "practice"]
    private static let supportedBreakers: Set<String> = ["me", "opp", "open", "none"]
    private static let supportedLayouts: Set<String> = ["open", "clustered", "problematic", "snookered", "none"]
    private static let supportedOutcomes: Set<String> = ["runout", "noRunout", "safety", "error", "other"]
    private static let supportedResults: Set<String> = ["won", "lost"]
    private static let supportedDrillOutcomes: Set<String> = ["success", "miss"]

    static func normalizeImportedSessions(_ sessions: [Session]) throws -> [Session] {
        guard !sessions.isEmpty else { throw JSONTransfer.TransferError.noSessions }

        let nowMillis = Int64(Date().timeIntervalSince1970 * 1000)
        var nextSessionID = max(nowMillis, (sessions.map(\.id).max() ?? 0) + 1)
        var usedSessionIDs = Set<Int64>()
        var usedSessionUUIDs = Set<String>()

        let normalized = sessions.map { session -> Session in
            var session = session

            session.label = session.label.trimmingCharacters(in: .whitespacesAndNewlines)
            session.opponent = session.opponent.trimmingCharacters(in: .whitespacesAndNewlines)
            session.game = supportedGames.contains(session.game) ? session.game : "8ball"
            session.type = supportedTypes.contains(session.type) ? session.type : "match"
            session.raceTo = session.raceTo.flatMap { $0 > 0 ? $0 : nil }
            session.durationSeconds = session.durationSeconds.flatMap { $0 >= 0 ? $0 : nil }
            session.performanceRating = session.performanceRating.map { min(max($0, 1), 10) }
            session.drillBallCount = session.drillBallCount.flatMap { $0 >= 0 ? $0 : nil }
            session.drillTargetCount = session.drillTargetCount.flatMap { $0 >= 0 ? $0 : nil }
            session.drillPrimarySkills = deduplicatedNonEmpty(session.drillPrimarySkills)
            session.drillSubskills = deduplicatedNonEmpty(session.drillSubskills)
            session.drillSecondarySkills = deduplicatedNonEmpty(session.drillSecondarySkills)

            if session.id <= 0 || usedSessionIDs.contains(session.id) {
                session.id = nextSessionID
                nextSessionID += 1
            }
            usedSessionIDs.insert(session.id)

            let trimmedUUID = session.sessionUUID.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedUUID.isEmpty || usedSessionUUIDs.contains(trimmedUUID) {
                session.sessionUUID = UUID().uuidString
            } else {
                session.sessionUUID = trimmedUUID
            }
            usedSessionUUIDs.insert(session.sessionUUID)

            session.racks = normalizeRacks(session.racks)
            return session
        }

        return normalized.sorted(by: Session.oldestFirst)
    }

    private static func normalizeRacks(_ racks: [Rack]) -> [Rack] {
        var usedRackUUIDs = Set<String>()
        return racks.enumerated().map { idx, original in
            var rack = original
            rack.index = idx + 1
            rack.id = UUID().uuidString

            let trimmedRackUUID = rack.rackUUID.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedRackUUID.isEmpty || usedRackUUIDs.contains(trimmedRackUUID) {
                rack.rackUUID = UUID().uuidString
            } else {
                rack.rackUUID = trimmedRackUUID
            }
            usedRackUUIDs.insert(rack.rackUUID)

            rack.breaker = supportedBreakers.contains(rack.breaker) ? rack.breaker : "me"
            rack.layout = supportedLayouts.contains(rack.layout) ? rack.layout : "open"
            rack.result = normalizedOptionalValue(rack.result, supported: supportedResults)
            rack.outcome = normalizedOptionalValue(rack.outcome, supported: supportedOutcomes)
            rack.drillOutcome = normalizedOptionalValue(rack.drillOutcome, supported: supportedDrillOutcomes)
            rack.breakBalls = max(0, rack.breakBalls)
            rack.fouls = max(0, rack.fouls)
            rack.badSafety = max(0, rack.badSafety)
            rack.badPosition = max(0, rack.badPosition)
            rack.patternCount = max(0, rack.patternCount)
            rack.missCount = max(0, rack.missCount)
            rack.drillBallsMade = rack.drillBallsMade.map { max(0, $0) }
            rack.drillTargetBallCount = rack.drillTargetBallCount.map { max(0, $0) }
            rack.drillTags = rack.drillTags.map(deduplicatedNonEmpty(_:))
            rack.drillNotes = rack.drillNotes?.trimmingCharacters(in: .whitespacesAndNewlines)
            if rack.drillNotes?.isEmpty == true { rack.drillNotes = nil }
            return rack
        }
    }

    private static func normalizedOptionalValue(_ value: String?, supported: Set<String>) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return supported.contains(trimmed) ? trimmed : nil
    }

    private static func deduplicatedNonEmpty(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for value in values {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            guard !seen.contains(trimmed) else { continue }
            seen.insert(trimmed)
            result.append(trimmed)
        }
        return result
    }
}
