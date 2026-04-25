import Foundation
import CloudKit

final class CloudKitStore {
    private let container: CKContainer
    private let db: CKDatabase

    init(container: CKContainer = .default()) {
        self.container = container
        self.db = container.privateCloudDatabase
    }

    struct RecordKeys {
        static let session = "Session"
        static let rack = "Rack"

        static let sessionId = "sessionId"
        static let label = "label"
        static let game = "game"
        static let type = "type"
        static let opponent = "opponent"
        static let ts = "ts"
        static let durationSeconds = "durationSeconds"
        static let performanceRating = "performanceRating"
        static let drillID = "drillID"
        static let drillTitle = "drillTitle"
        static let drillKind = "drillKind"
        static let drillDifficulty = "drillDifficulty"
        static let drillBallCount = "drillBallCount"
        static let drillPrimarySkill = "drillPrimarySkill"
        static let drillPrimarySkills = "drillPrimarySkills"
        static let drillSubskills = "drillSubskills"
        static let drillSecondarySkills = "drillSecondarySkills"
        static let drillTargetType = "drillTargetType"
        static let drillTargetCount = "drillTargetCount"

        static let sessionRef = "sessionRef"
        static let index = "index"
        static let result = "result"
        static let breaker = "breaker"
        static let breakBalls = "breakBalls"
        static let breakFoul = "breakFoul"
        static let layout = "layout"
        static let outcome = "outcome"
        static let fouls = "fouls"
        static let badSafety = "badSafety"
        static let badPosition = "badPosition"
        static let missCount = "missCount"
        static let runoutFirst = "runoutFirst"
        static let breakAndRun = "breakAndRun"
        static let drillOutcome = "drillOutcome"
        static let drillTags = "drillTags"
        static let drillNotes = "drillNotes"
        static let drillBallsMade = "drillBallsMade"
        static let drillTargetBallCount = "drillTargetBallCount"
        static let drillRackDifficulty = "drillRackDifficulty"
    }

    func fetchAllSessions() async throws -> [Session] {
        let sessionQuery = CKQuery(recordType: RecordKeys.session, predicate: NSPredicate(value: true))
        sessionQuery.sortDescriptors = [NSSortDescriptor(key: RecordKeys.ts, ascending: true)]
        let sessionRecords = try await fetchAllRecords(query: sessionQuery)

        let rackQuery = CKQuery(recordType: RecordKeys.rack, predicate: NSPredicate(value: true))
        let rackRecords = try await fetchAllRecords(query: rackQuery)

        var racksBySession: [CKRecord.ID: [Rack]] = [:]
        for record in rackRecords {
            guard let ref = record[RecordKeys.sessionRef] as? CKRecord.Reference else { continue }
            var arr = racksBySession[ref.recordID] ?? []
            if let rack = rackFromRecord(record) {
                arr.append(rack)
                racksBySession[ref.recordID] = arr
            }
        }
        for key in racksBySession.keys {
            racksBySession[key]?.sort(by: { $0.index < $1.index })
        }

        var sessions: [Session] = []
        for record in sessionRecords {
            let session = sessionFromRecord(record, racks: racksBySession[record.recordID] ?? [])
            sessions.append(session)
        }
        return sessions
    }

    func saveSession(_ session: Session) async throws {
        let sessionRecord = recordFromSession(session)
        var rackRecords: [CKRecord] = []
        for rack in session.racks {
            let r = recordFromRack(rack, sessionRecordID: sessionRecord.recordID)
            rackRecords.append(r)
        }

        let op = CKModifyRecordsOperation(recordsToSave: [sessionRecord] + rackRecords, recordIDsToDelete: nil)
        op.savePolicy = .changedKeys
        try await withCheckedThrowingContinuation { cont in
            op.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    cont.resume()
                case .failure(let error):
                    cont.resume(throwing: error)
                }
            }
            db.add(op)
        }
    }

    func updateSessionMeta(_ session: Session) async throws {
        let sessionRecord = recordFromSession(session)
        let op = CKModifyRecordsOperation(recordsToSave: [sessionRecord], recordIDsToDelete: nil)
        op.savePolicy = .changedKeys
        try await withCheckedThrowingContinuation { cont in
            op.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    cont.resume()
                case .failure(let error):
                    cont.resume(throwing: error)
                }
            }
            db.add(op)
        }
    }

    func deleteSessions(_ sessionIDs: [Int64]) async throws {
        let recordIDs = sessionIDs.map { CKRecord.ID(recordName: String($0)) }
        let op = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)
        try await withCheckedThrowingContinuation { cont in
            op.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    cont.resume()
                case .failure(let error):
                    cont.resume(throwing: error)
                }
            }
            db.add(op)
        }
    }

    private func fetchAllRecords(query: CKQuery) async throws -> [CKRecord] {
        var records: [CKRecord] = []
        var cursor: CKQueryOperation.Cursor?
        repeat {
            let (batch, nextCursor) = try await fetchBatch(query: query, cursor: cursor)
            records.append(contentsOf: batch)
            cursor = nextCursor
        } while cursor != nil
        return records
    }

    private func fetchBatch(query: CKQuery, cursor: CKQueryOperation.Cursor?) async throws -> ([CKRecord], CKQueryOperation.Cursor?) {
        try await withCheckedThrowingContinuation { cont in
            let op: CKQueryOperation
            if let cursor = cursor {
                op = CKQueryOperation(cursor: cursor)
            } else {
                op = CKQueryOperation(query: query)
            }
            var batch: [CKRecord] = []
            op.recordMatchedBlock = { _, result in
                if case .success(let record) = result {
                    batch.append(record)
                }
            }
            op.queryResultBlock = { result in
                switch result {
                case .success(let cursor):
                    cont.resume(returning: (batch, cursor))
                case .failure(let error):
                    cont.resume(throwing: error)
                }
            }
            db.add(op)
        }
    }

    private func recordFromSession(_ session: Session) -> CKRecord {
        let recordID = CKRecord.ID(recordName: String(session.id))
        let record = CKRecord(recordType: RecordKeys.session, recordID: recordID)
        record[RecordKeys.sessionId] = NSNumber(value: session.id)
        record[RecordKeys.label] = session.label
        record[RecordKeys.opponent] = session.opponent
        record[RecordKeys.game] = session.game
        record[RecordKeys.type] = session.type
        record[RecordKeys.ts] = session.ts
        if let durationSeconds = session.durationSeconds {
            record[RecordKeys.durationSeconds] = durationSeconds
        }
        if let performanceRating = session.performanceRating {
            record[RecordKeys.performanceRating] = performanceRating
        }
        if let drillID = session.drillID { record[RecordKeys.drillID] = drillID }
        if let drillTitle = session.drillTitle { record[RecordKeys.drillTitle] = drillTitle }
        if let drillKind = session.drillKind { record[RecordKeys.drillKind] = drillKind }
        if let drillDifficulty = session.drillDifficulty { record[RecordKeys.drillDifficulty] = drillDifficulty }
        if let drillBallCount = session.drillBallCount { record[RecordKeys.drillBallCount] = drillBallCount }
        if let drillPrimarySkill = session.drillPrimarySkill { record[RecordKeys.drillPrimarySkill] = drillPrimarySkill }
        if !session.drillPrimaryLabels.isEmpty { record[RecordKeys.drillPrimarySkills] = session.drillPrimaryLabels as NSArray }
        if !session.drillSubskills.isEmpty { record[RecordKeys.drillSubskills] = session.drillSubskills as NSArray }
        if !session.drillSecondaryLabels.isEmpty { record[RecordKeys.drillSecondarySkills] = session.drillSecondaryLabels as NSArray }
        if let drillTargetType = session.drillTargetType { record[RecordKeys.drillTargetType] = drillTargetType }
        if let drillTargetCount = session.drillTargetCount { record[RecordKeys.drillTargetCount] = drillTargetCount }
        return record
    }

    private func recordFromRack(_ rack: Rack, sessionRecordID: CKRecord.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: rack.id)
        let record = CKRecord(recordType: RecordKeys.rack, recordID: recordID)
        record[RecordKeys.sessionRef] = CKRecord.Reference(recordID: sessionRecordID, action: .deleteSelf)
        record[RecordKeys.index] = rack.index
        record[RecordKeys.result] = rack.result
        record[RecordKeys.breaker] = rack.breaker
        record[RecordKeys.breakBalls] = rack.breakBalls
        record[RecordKeys.breakFoul] = rack.breakFoul
        record[RecordKeys.layout] = rack.layout
        record[RecordKeys.outcome] = rack.outcome
        record[RecordKeys.fouls] = rack.fouls
        record[RecordKeys.badSafety] = rack.badSafety
        record[RecordKeys.badPosition] = rack.badPosition
        record[RecordKeys.missCount] = rack.missCount
        record[RecordKeys.runoutFirst] = rack.runoutFirst
        record[RecordKeys.breakAndRun] = rack.breakAndRun
        if let drillOutcome = rack.drillOutcome { record[RecordKeys.drillOutcome] = drillOutcome }
        if let drillTags = rack.drillTags, !drillTags.isEmpty { record[RecordKeys.drillTags] = drillTags as NSArray }
        if let drillNotes = rack.drillNotes { record[RecordKeys.drillNotes] = drillNotes }
        if let drillBallsMade = rack.drillBallsMade { record[RecordKeys.drillBallsMade] = drillBallsMade }
        if let drillTargetBallCount = rack.drillTargetBallCount { record[RecordKeys.drillTargetBallCount] = drillTargetBallCount }
        if let drillDifficulty = rack.drillDifficulty { record[RecordKeys.drillRackDifficulty] = drillDifficulty }
        return record
    }

    private func sessionFromRecord(_ record: CKRecord, racks: [Rack]) -> Session {
        let id = (record[RecordKeys.sessionId] as? NSNumber)?.int64Value ?? Int64(record.recordID.recordName) ?? 0
        let label = record[RecordKeys.label] as? String ?? ""
        let opponent = record[RecordKeys.opponent] as? String ?? ""
        let game = record[RecordKeys.game] as? String ?? "8ball"
        let type = record[RecordKeys.type] as? String ?? "match"
        let ts = record[RecordKeys.ts] as? Date ?? Date()
        let duration = record[RecordKeys.durationSeconds] as? Int
        let rating = record[RecordKeys.performanceRating] as? Int
        let drillPrimarySkills = (record[RecordKeys.drillPrimarySkills] as? [String])
            ?? (record[RecordKeys.drillPrimarySkills] as? NSArray)?.compactMap { $0 as? String }
            ?? []
        let drillSubskills = (record[RecordKeys.drillSubskills] as? [String])
            ?? (record[RecordKeys.drillSubskills] as? NSArray)?.compactMap { $0 as? String }
            ?? []
        let drillSecondarySkills = (record[RecordKeys.drillSecondarySkills] as? [String])
            ?? (record[RecordKeys.drillSecondarySkills] as? NSArray)?.compactMap { $0 as? String }
            ?? []
        return Session(
            id: id,
            sessionUUID: "session-\(id)",
            label: label,
            opponent: opponent,
            game: game,
            type: type,
            ts: ts,
            racks: racks,
            durationSeconds: duration,
            performanceRating: rating,
            drillID: record[RecordKeys.drillID] as? String,
            drillTitle: record[RecordKeys.drillTitle] as? String,
            drillKind: record[RecordKeys.drillKind] as? String,
            drillDifficulty: record[RecordKeys.drillDifficulty] as? String,
            drillBallCount: record[RecordKeys.drillBallCount] as? Int,
            drillPrimarySkill: record[RecordKeys.drillPrimarySkill] as? String,
            drillPrimarySkills: drillPrimarySkills,
            drillSubskills: drillSubskills,
            drillSecondarySkills: drillSecondarySkills,
            drillTargetType: record[RecordKeys.drillTargetType] as? String,
            drillTargetCount: record[RecordKeys.drillTargetCount] as? Int
        )
    }

    private func rackFromRecord(_ record: CKRecord) -> Rack? {
        guard let index = record[RecordKeys.index] as? Int else { return nil }
        let id = record.recordID.recordName
        let result = record[RecordKeys.result] as? String
        let breaker = record[RecordKeys.breaker] as? String ?? "me"
        let breakBalls = record[RecordKeys.breakBalls] as? Int ?? -1
        let breakFoul = record[RecordKeys.breakFoul] as? Bool ?? false
        let layout = record[RecordKeys.layout] as? String ?? "open"
        let outcome = record[RecordKeys.outcome] as? String
        let fouls = record[RecordKeys.fouls] as? Int ?? 0
        let badSafety = record[RecordKeys.badSafety] as? Int ?? 0
        let badPosition = record[RecordKeys.badPosition] as? Int ?? 0
        let missCount = record[RecordKeys.missCount] as? Int ?? (
            (record["missEasy"] as? Int ?? 0) +
            (record["missMed"] as? Int ?? 0) +
            (record["missHard"] as? Int ?? 0)
        )
        let runoutFirst = record[RecordKeys.runoutFirst] as? Bool ?? false
        let breakAndRun = record[RecordKeys.breakAndRun] as? Bool ?? false
        let drillTags = (record[RecordKeys.drillTags] as? [String])
            ?? (record[RecordKeys.drillTags] as? NSArray)?.compactMap { $0 as? String }

        return Rack(
            id: id,
            rackUUID: "rack-\(id)",
            index: index,
            result: result,
            breaker: breaker,
            breakBalls: breakBalls,
            breakFoul: breakFoul,
            layout: layout,
            outcome: outcome,
            fouls: fouls,
            badSafety: badSafety,
            badPosition: badPosition,
            missCount: missCount,
            runoutFirst: runoutFirst,
            breakAndRun: breakAndRun,
            drillOutcome: record[RecordKeys.drillOutcome] as? String,
            drillTags: drillTags,
            drillNotes: record[RecordKeys.drillNotes] as? String,
            drillBallsMade: record[RecordKeys.drillBallsMade] as? Int,
            drillTargetBallCount: record[RecordKeys.drillTargetBallCount] as? Int,
            drillDifficulty: record[RecordKeys.drillRackDifficulty] as? String
        )
    }
}
