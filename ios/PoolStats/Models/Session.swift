import Foundation

struct Session: Identifiable, Codable, Hashable {
    var id: Int64
    var label: String
    var game: String
    var type: String
    var ts: Date
    var racks: [Rack]

    init(
        id: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        label: String = "",
        game: String,
        type: String,
        ts: Date = Date(),
        racks: [Rack] = []
    ) {
        self.id = id
        self.label = label
        self.game = game
        self.type = type
        self.ts = ts
        self.racks = racks
    }

    var isPractice: Bool { type == "practice" }
}
