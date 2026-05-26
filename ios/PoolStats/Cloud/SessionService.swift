import Foundation

protocol SessionServicing {
    func fetchAllSessions() async throws -> [Session]
    func saveSession(_ session: Session) async throws
    func updateSessionMeta(_ session: Session) async throws
    func deleteSessions(_ ids: [Int64]) async throws
    func replaceAllSessions(existingIDs: [Int64], with newSessions: [Session]) async throws
    func deleteAllUserData(knownSessionIDs: [Int64]) async throws
    func hasAnyUserData() async throws -> Bool
}

final class SessionService: SessionServicing {
    private let cloud = CloudKitStore()

    func fetchAllSessions() async throws -> [Session] {
        try await cloud.fetchAllSessions()
    }

    func saveSession(_ session: Session) async throws {
        try await cloud.saveSession(session)
    }

    func updateSessionMeta(_ session: Session) async throws {
        try await cloud.updateSessionMeta(session)
    }

    func deleteSessions(_ ids: [Int64]) async throws {
        try await cloud.deleteSessions(ids)
    }

    func replaceAllSessions(existingIDs: [Int64], with newSessions: [Session]) async throws {
        if !existingIDs.isEmpty {
            try await cloud.deleteSessions(existingIDs)
        }
        for s in newSessions {
            try await cloud.saveSession(s)
        }
    }

    func deleteAllUserData(knownSessionIDs: [Int64]) async throws {
        try await cloud.deleteAllUserData(knownSessionIDs: knownSessionIDs)
    }

    func hasAnyUserData() async throws -> Bool {
        try await cloud.hasAnyUserData()
    }
}
