import Foundation

final class WatchQueueStore {
    private let localURL: URL
    private var queued: [WatchSyncEnvelope] = []

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("PoolStatsWatch", isDirectory: true)
        localURL = dir.appendingPathComponent("watch-queue.json")
        load()
    }

    func enqueue(_ envelope: WatchSyncEnvelope) {
        queued.append(envelope)
        save()
    }

    func drain() -> [WatchSyncEnvelope] {
        guard queued.isEmpty == false else { return [] }
        let copy = queued
        queued.removeAll()
        save()
        return copy
    }

    private func load() {
        guard let data = try? Data(contentsOf: localURL) else {
            return
        }
        guard data.isEmpty == false else {
            try? FileManager.default.removeItem(at: localURL)
            return
        }
        do {
            queued = try JSONDecoder().decode([WatchSyncEnvelope].self, from: data)
            if queued.isEmpty {
                try? FileManager.default.removeItem(at: localURL)
            }
        } catch {
            queued = []
            try? FileManager.default.removeItem(at: localURL)
        }
    }

    private func save() {
        if queued.isEmpty {
            try? FileManager.default.removeItem(at: localURL)
            return
        }
        guard let data = try? JSONEncoder().encode(queued) else { return }
        let dir = localURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: localURL, options: .atomic)
    }
}
