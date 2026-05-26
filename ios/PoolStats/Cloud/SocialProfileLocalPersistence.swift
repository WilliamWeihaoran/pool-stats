import Foundation

struct SocialProfileLocalPersistence {
    let profileURL: URL
    let friendsURL: URL
    let blockedPlayersURL: URL
    let outgoingSharesURL: URL
    let incomingSharesURL: URL
    let pendingDeletionProfileURL: URL

    init(baseDirectory: URL? = nil) {
        let directory = Self.storageDirectory(baseDirectory: baseDirectory)
        profileURL = directory.appendingPathComponent("social-profile.json")
        friendsURL = directory.appendingPathComponent("social-friends.json")
        blockedPlayersURL = directory.appendingPathComponent("social-blocked-players.json")
        outgoingSharesURL = directory.appendingPathComponent("social-outgoing-shares.json")
        incomingSharesURL = directory.appendingPathComponent("social-incoming-shares.json")
        pendingDeletionProfileURL = directory.appendingPathComponent("social-pending-account-deletion.json")
    }

    func load<Value: Decodable>(_ type: Value.Type, from url: URL) -> Value? {
        guard let data = try? Data(contentsOf: url), !data.isEmpty else { return nil }
        return try? Self.decoder.decode(type, from: data)
    }

    func save<Value: Encodable>(_ value: Value, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try Self.encoder.encode(value)
        try data.write(to: url, options: [.atomic])
    }

    func removeAll() throws {
        try remove(profileURL)
        try remove(friendsURL)
        try remove(blockedPlayersURL)
        try remove(outgoingSharesURL)
        try remove(incomingSharesURL)
    }

    func removePendingDeletionProfile() throws {
        try remove(pendingDeletionProfileURL)
    }

    private func remove(_ url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    private static func storageDirectory(baseDirectory: URL?) -> URL {
        if let baseDirectory {
            return baseDirectory
        }

        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("PoolStats", isDirectory: true)
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
