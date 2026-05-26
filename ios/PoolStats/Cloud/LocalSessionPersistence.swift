import Foundation

struct LocalSessionCache {
    let url: URL

    init(url: URL = LocalSessionCache.defaultURL()) {
        self.url = url
    }

    func loadSessions() -> [Session] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        guard data.isEmpty == false else {
            clear()
            return []
        }
        guard let loaded = try? JSONTransfer.importSessions(data) else {
            clear()
            return []
        }
        return loaded
    }

    func saveSessions(_ sessions: [Session]) {
        guard let data = try? JSONTransfer.exportSessions(sessions) else { return }
        createDirectoryIfNeeded()
        try? data.write(to: url, options: .atomic)
    }

    func clear() {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    private func createDirectoryIfNeeded() {
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }

    fileprivate static func defaultURL(fileManager: FileManager = .default) -> URL {
        baseDirectory(fileManager: fileManager).appendingPathComponent("sessions.json")
    }

    private static func baseDirectory(fileManager: FileManager) -> URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return base.appendingPathComponent("PoolStats", isDirectory: true)
    }
}

struct DeletedSessionIDStore {
    let url: URL

    init(url: URL = DeletedSessionIDStore.defaultURL()) {
        self.url = url
    }

    func load() -> Set<Int64> {
        guard let data = try? Data(contentsOf: url) else {
            return []
        }
        guard data.isEmpty == false else {
            clear()
            return []
        }
        guard let ids = try? JSONDecoder().decode([Int64].self, from: data) else {
            clear()
            return []
        }
        return Set(ids)
    }

    func save(_ ids: Set<Int64>) {
        createDirectoryIfNeeded()
        guard !ids.isEmpty else {
            clear()
            return
        }

        let sortedIDs = Array(ids).sorted()
        guard let data = try? JSONEncoder().encode(sortedIDs) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func clear() {
        try? FileManager.default.removeItem(at: url)
    }

    private func createDirectoryIfNeeded() {
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }

    private static func defaultURL(fileManager: FileManager = .default) -> URL {
        LocalSessionCache
            .defaultURL(fileManager: fileManager)
            .deletingLastPathComponent()
            .appendingPathComponent("deleted-session-ids.json")
    }
}
