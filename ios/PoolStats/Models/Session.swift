import Foundation

struct Session: Identifiable, Codable, Hashable {
    var id: Int64
    var sessionUUID: String
    var label: String
    var opponent: String
    var game: String
    var type: String
    var ts: Date
    var racks: [Rack]
    var durationSeconds: Int?
    var performanceRating: Int?

    init(
        id: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        sessionUUID: String = UUID().uuidString,
        label: String = "",
        opponent: String = "",
        game: String,
        type: String,
        ts: Date = Date(),
        racks: [Rack] = [],
        durationSeconds: Int? = nil,
        performanceRating: Int? = nil
    ) {
        self.id = id
        self.sessionUUID = sessionUUID
        self.label = label
        self.opponent = opponent
        self.game = game
        self.type = type
        self.ts = ts
        self.racks = racks
        self.durationSeconds = durationSeconds
        self.performanceRating = performanceRating
    }

    enum CodingKeys: String, CodingKey {
        case id
        case sessionUUID
        case label
        case opponent
        case game
        case type
        case ts
        case racks
        case durationSeconds
        case performanceRating
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int64.self, forKey: .id)
        sessionUUID = try c.decodeIfPresent(String.self, forKey: .sessionUUID) ?? "session-\(id)"
        label = try c.decode(String.self, forKey: .label)
        opponent = try c.decode(String.self, forKey: .opponent)
        game = try c.decode(String.self, forKey: .game)
        type = try c.decode(String.self, forKey: .type)
        ts = try c.decode(Date.self, forKey: .ts)
        racks = try c.decode([Rack].self, forKey: .racks)
        durationSeconds = try c.decodeIfPresent(Int.self, forKey: .durationSeconds)
        performanceRating = try c.decodeIfPresent(Int.self, forKey: .performanceRating)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(sessionUUID, forKey: .sessionUUID)
        try c.encode(label, forKey: .label)
        try c.encode(opponent, forKey: .opponent)
        try c.encode(game, forKey: .game)
        try c.encode(type, forKey: .type)
        try c.encode(ts, forKey: .ts)
        try c.encode(racks, forKey: .racks)
        try c.encodeIfPresent(durationSeconds, forKey: .durationSeconds)
        try c.encodeIfPresent(performanceRating, forKey: .performanceRating)
    }

    var isPractice: Bool { type == "practice" }
    var wins: Int { racks.filter { $0.result == "won" }.count }
    var losses: Int { racks.filter { $0.result == "lost" }.count }
    var isDraw: Bool { !isPractice && wins == losses && wins > 0 }
    var gameLabel: String { game == "8ball" ? "8-ball" : "9-ball" }
    var typeLabel: String { isPractice ? "Practice" : "Match" }
    var displayLabel: String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        let gameName = game == "8ball" ? "8 ball" : "9 ball"
        let modeName = isPractice ? "practice" : "match"
        return "\(gameName) \(modeName)"
    }
}

extension Session {
    static let rackSetupBufferSeconds: TimeInterval = 45

    func bufferedPaceFill(totalSeconds: TimeInterval, targetPerRack: TimeInterval = 60) -> (buffer: Int, active: Int) {
        let pacePercent = bufferedPacePercent(totalSeconds: totalSeconds, targetPerRack: targetPerRack)
        let bufferPercent = Int(min(100, max(0, Self.rackSetupBufferSeconds / targetPerRack * 100)))
        let bufferFill = min(pacePercent, bufferPercent)
        let activeFill = max(0, pacePercent - bufferFill)
        return (bufferFill, activeFill)
    }

    func bufferedSessionSeconds(totalSeconds: TimeInterval) -> TimeInterval {
        totalSeconds + Self.rackSetupBufferSeconds * Double(max(0, racks.count - 1))
    }

    func bufferedPaceBufferPercent(targetPerRack: TimeInterval = 60) -> Int {
        Int(min(100, max(0, Self.rackSetupBufferSeconds / targetPerRack * 100)))
    }

    func bufferedAverageRackSeconds(totalSeconds: TimeInterval) -> TimeInterval {
        let rackCount = max(racks.count, 1)
        return bufferedSessionSeconds(totalSeconds: totalSeconds) / Double(rackCount)
    }

    func bufferedPacePercent(totalSeconds: TimeInterval, targetPerRack: TimeInterval = 60) -> Int {
        let avg = bufferedAverageRackSeconds(totalSeconds: totalSeconds)
        return Int(min(100, max(0, avg / targetPerRack * 100)))
    }
}
