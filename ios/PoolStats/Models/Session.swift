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
    var drillID: String?
    var drillTitle: String?
    var drillKind: String?
    var drillDifficulty: String?
    var drillBallCount: Int?
    var drillPrimarySkill: String?
    var drillPrimarySkills: [String]
    var drillSubskills: [String]
    var drillSecondarySkills: [String]
    var drillTargetType: String?
    var drillTargetCount: Int?

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
        performanceRating: Int? = nil,
        drillID: String? = nil,
        drillTitle: String? = nil,
        drillKind: String? = nil,
        drillDifficulty: String? = nil,
        drillBallCount: Int? = nil,
        drillPrimarySkill: String? = nil,
        drillPrimarySkills: [String] = [],
        drillSubskills: [String] = [],
        drillSecondarySkills: [String] = [],
        drillTargetType: String? = nil,
        drillTargetCount: Int? = nil
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
        self.drillID = drillID
        self.drillTitle = drillTitle
        self.drillKind = drillKind
        self.drillDifficulty = drillDifficulty
        self.drillBallCount = drillBallCount
        self.drillPrimarySkill = drillPrimarySkill
        self.drillPrimarySkills = drillPrimarySkills
        self.drillSubskills = drillSubskills
        self.drillSecondarySkills = drillSecondarySkills
        self.drillTargetType = drillTargetType
        self.drillTargetCount = drillTargetCount
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
        case drillID
        case drillTitle
        case drillKind
        case drillDifficulty
        case drillBallCount
        case drillPrimarySkill
        case drillPrimarySkills
        case drillSubskills
        case drillSecondarySkills
        case drillTargetType
        case drillTargetCount
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
        drillID = try c.decodeIfPresent(String.self, forKey: .drillID)
        drillTitle = try c.decodeIfPresent(String.self, forKey: .drillTitle)
        drillKind = try c.decodeIfPresent(String.self, forKey: .drillKind)
        drillDifficulty = try c.decodeIfPresent(String.self, forKey: .drillDifficulty)
        drillBallCount = try c.decodeIfPresent(Int.self, forKey: .drillBallCount)
        drillPrimarySkill = try c.decodeIfPresent(String.self, forKey: .drillPrimarySkill)
        drillPrimarySkills = try c.decodeIfPresent([String].self, forKey: .drillPrimarySkills) ?? []
        drillSubskills = try c.decodeIfPresent([String].self, forKey: .drillSubskills) ?? []
        drillSecondarySkills = try c.decodeIfPresent([String].self, forKey: .drillSecondarySkills) ?? []
        drillTargetType = try c.decodeIfPresent(String.self, forKey: .drillTargetType)
        drillTargetCount = try c.decodeIfPresent(Int.self, forKey: .drillTargetCount)
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
        try c.encodeIfPresent(drillID, forKey: .drillID)
        try c.encodeIfPresent(drillTitle, forKey: .drillTitle)
        try c.encodeIfPresent(drillKind, forKey: .drillKind)
        try c.encodeIfPresent(drillDifficulty, forKey: .drillDifficulty)
        try c.encodeIfPresent(drillBallCount, forKey: .drillBallCount)
        try c.encodeIfPresent(drillPrimarySkill, forKey: .drillPrimarySkill)
        if !drillPrimarySkills.isEmpty { try c.encode(drillPrimarySkills, forKey: .drillPrimarySkills) }
        if !drillSubskills.isEmpty { try c.encode(drillSubskills, forKey: .drillSubskills) }
        if !drillSecondarySkills.isEmpty { try c.encode(drillSecondarySkills, forKey: .drillSecondarySkills) }
        try c.encodeIfPresent(drillTargetType, forKey: .drillTargetType)
        try c.encodeIfPresent(drillTargetCount, forKey: .drillTargetCount)
    }

    var isPractice: Bool { type == "practice" }
    var isDrillPractice: Bool { isPractice && drillID != nil }
    var wins: Int { racks.filter { $0.result == "won" }.count }
    var losses: Int { racks.filter { $0.result == "lost" }.count }
    var isDraw: Bool { !isPractice && wins == losses && wins > 0 }
    var gameLabel: String { game == "8ball" ? "8-ball" : "9-ball" }
    var typeLabel: String { isDrillPractice ? "Drill practice" : (isPractice ? "Practice" : "Match") }
    var displayLabel: String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        if isDrillPractice, let drillTitle { return drillTitle }
        let gameName = game == "8ball" ? "8 ball" : "9 ball"
        let modeName = isPractice ? "practice" : "match"
        return "\(gameName) \(modeName)"
    }
    var drillPrimaryLabels: [String] {
        let labels = drillPrimarySkills.isEmpty ? [drillPrimarySkill].compactMap { $0 } : drillPrimarySkills
        return Array(labels.prefix(3))
    }
    var drillSecondaryLabels: [String] {
        let labels = drillSecondarySkills.isEmpty ? drillSubskills : drillSecondarySkills
        return Array(labels.prefix(3))
    }
    var drillSkillSummary: String {
        drillPrimaryLabels.joined(separator: " · ")
    }
    var drillAttempts: Int { racks.filter { $0.drillOutcome != nil }.count }
    var drillTargetLabel: String? {
        guard let drillTargetCount, drillTargetCount > 0 else { return nil }
        if drillTargetType == "attempts" { return "Target: \(drillTargetCount) attempts" }
        return "Target: \(drillTargetCount) successes"
    }
    var drillTargetProgress: (current: Int, target: Int)? {
        guard let drillTargetCount, drillTargetCount > 0 else { return nil }
        let current = drillTargetType == "attempts" ? drillAttempts : drillSuccesses
        return (current, drillTargetCount)
    }
    var drillSuccesses: Int { racks.filter { $0.drillOutcome == "success" }.count }
    var drillMisses: Int { racks.filter { $0.drillOutcome == "miss" }.count }
    var drillSuccessRate: Int? {
        let attempts = drillAttempts
        guard attempts > 0 else { return nil }
        return Int(round(Double(drillSuccesses) / Double(attempts) * 100))
    }

    var drillDifficultyLevel: DrillDifficultyLevel? {
        guard let drillDifficulty else { return nil }
        return DrillDifficultyLevel(rawValue: drillDifficulty)
    }
    var drillDifficultyLabel: String {
        switch drillDifficulty {
        case "beginner": return "Beginner"
        case "easy": return "Easy"
        case "standard": return "Standard"
        case "hard": return "Hard"
        case "expert": return "Expert"
        default: return "Drill"
        }
    }

    static func newestFirst(_ lhs: Session, _ rhs: Session) -> Bool {
        if lhs.ts != rhs.ts { return lhs.ts > rhs.ts }
        if lhs.id != rhs.id { return lhs.id > rhs.id }
        return lhs.sessionUUID > rhs.sessionUUID
    }

    static func oldestFirst(_ lhs: Session, _ rhs: Session) -> Bool {
        if lhs.ts != rhs.ts { return lhs.ts < rhs.ts }
        if lhs.id != rhs.id { return lhs.id < rhs.id }
        return lhs.sessionUUID < rhs.sessionUUID
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

    func adjustedSessionSeconds(totalSeconds: TimeInterval, rackCount: Int? = nil) -> TimeInterval {
        let count = max(rackCount ?? max(racks.count, 1), 1)
        return max(0, totalSeconds - Self.rackSetupBufferSeconds * Double(count))
    }

    func bufferedSessionSeconds(totalSeconds: TimeInterval) -> TimeInterval {
        adjustedSessionSeconds(totalSeconds: totalSeconds)
    }

    func bufferedPaceBufferPercent(targetPerRack: TimeInterval = 60) -> Int {
        Int(min(100, max(0, Self.rackSetupBufferSeconds / targetPerRack * 100)))
    }

    func bufferedAverageRackSeconds(totalSeconds: TimeInterval, rackCount: Int? = nil) -> TimeInterval {
        let count = max(rackCount ?? max(racks.count, 1), 1)
        return adjustedSessionSeconds(totalSeconds: totalSeconds, rackCount: count) / Double(count)
    }

    func bufferedPacePercent(totalSeconds: TimeInterval, targetPerRack: TimeInterval = 60, rackCount: Int? = nil) -> Int {
        let avg = bufferedAverageRackSeconds(totalSeconds: totalSeconds, rackCount: rackCount)
        return Int(min(100, max(0, avg / targetPerRack * 100)))
    }
}
