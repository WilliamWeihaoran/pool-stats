import Foundation

final class WatchQueueStore {
    private let localURL: URL
    private var queued: [WatchSyncEnvelope] = []

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("PoolStatsWatch", isDirectory: true)
        localURL = dir.appendingPathComponent("watch-queue.json")
        load()
    }

    func enqueue(_ envelope: WatchSyncEnvelope) {
        queued.append(envelope)
        save()
    }

    func drain() -> [WatchSyncEnvelope] {
        let copy = queued
        queued.removeAll()
        save()
        return copy
    }

    private func load() {
        guard let data = try? Data(contentsOf: localURL),
              let list = try? JSONDecoder().decode([WatchSyncEnvelope].self, from: data) else {
            return
        }
        queued = list
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(queued) else { return }
        let dir = localURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: localURL, options: .atomic)
    }
}
