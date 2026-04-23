import Foundation

struct Session: Identifiable, Codable, Hashable {
    var id: Int64
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
        self.label = label
        self.opponent = opponent
        self.game = game
        self.type = type
        self.ts = ts
        self.racks = racks
        self.durationSeconds = durationSeconds
        self.performanceRating = performanceRating
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
