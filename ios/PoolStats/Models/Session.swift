import Foundation

struct Session: Identifiable, Codable, Hashable {
    var id: Int64
    var label: String
    var game: String
    var type: String
    var ts: Date
    var racks: [Rack]
    var durationSeconds: Int?

    init(
        id: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        label: String = "",
        game: String,
        type: String,
        ts: Date = Date(),
        racks: [Rack] = [],
        durationSeconds: Int? = nil
    ) {
        self.id = id
        self.label = label
        self.game = game
        self.type = type
        self.ts = ts
        self.racks = racks
        self.durationSeconds = durationSeconds
    }

    var isPractice: Bool { type == "practice" }
}
