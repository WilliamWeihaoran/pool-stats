import Foundation

struct DrillTemplate: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var kind: DrillKind
    var pictureID: String
    var description: String
    var primarySkills: [String]
    var secondarySkills: [String]
    var countUnit: DrillCountUnit
    var difficultyLevels: [DrillDifficulty]
    var instructions: [String]

    init(
        id: String,
        title: String,
        kind: DrillKind,
        pictureID: String,
        description: String,
        primarySkills: [String],
        secondarySkills: [String],
        countUnit: DrillCountUnit = .balls,
        difficultyLevels: [DrillDifficulty],
        instructions: [String]
    ) {
        self.id = id
        self.title = title
        self.kind = kind
        self.pictureID = pictureID
        self.description = description
        self.primarySkills = primarySkills
        self.secondarySkills = secondarySkills
        self.countUnit = countUnit
        self.difficultyLevels = difficultyLevels
        self.instructions = instructions
    }

    var primarySkill: String { primarySkills.first ?? "Overall" }
    var subskills: [String] { secondarySkills }

    var standardDifficulty: DrillDifficulty {
        difficultyLevels.first(where: { $0.level == .standard }) ?? difficultyLevels[0]
    }

    var difficultyRangeText: String {
        guard let minCount = difficultyLevels.map(\.ballCount).min(),
              let maxCount = difficultyLevels.map(\.ballCount).max() else { return "Adaptive" }
        return countUnit.rangeText(min: minCount, max: maxCount)
    }

    func countText(_ count: Int) -> String {
        countUnit.text(for: count)
    }

    func difficultySummary(_ difficulty: DrillDifficulty) -> String {
        "\(difficulty.level.label) · \(countText(difficulty.ballCount))"
    }

    func progressTitle() -> String {
        countUnit.progressTitle
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case kind
        case pictureID
        case description
        case primarySkills
        case secondarySkills
        case countUnit
        case difficultyLevels
        case instructions
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        kind = try c.decode(DrillKind.self, forKey: .kind)
        pictureID = try c.decode(String.self, forKey: .pictureID)
        description = try c.decode(String.self, forKey: .description)
        primarySkills = try c.decode([String].self, forKey: .primarySkills)
        secondarySkills = try c.decode([String].self, forKey: .secondarySkills)
        countUnit = try c.decodeIfPresent(DrillCountUnit.self, forKey: .countUnit) ?? .balls
        difficultyLevels = try c.decode([DrillDifficulty].self, forKey: .difficultyLevels)
        instructions = try c.decode([String].self, forKey: .instructions)
    }
}

enum DrillKind: String, Codable, Hashable {
    case staticLayout
    case randomLayout
}

enum DrillCountUnit: String, Codable, Hashable {
    case balls
    case shots
    case targets
    case kicks
    case banks
    case safeties
    case breaks
    case lags
    case attempts
    case reps
    case routes
    case caroms
    case jumps

    var title: String {
        switch self {
        case .balls: return "Balls"
        case .shots: return "Shots"
        case .targets: return "Targets"
        case .kicks: return "Kicks"
        case .banks: return "Banks"
        case .safeties: return "Safeties"
        case .breaks: return "Breaks"
        case .lags: return "Lags"
        case .attempts: return "Attempts"
        case .reps: return "Reps"
        case .routes: return "Routes"
        case .caroms: return "Caroms"
        case .jumps: return "Jumps"
        }
    }

    var singular: String {
        switch self {
        case .balls: return "ball"
        case .shots: return "shot"
        case .targets: return "target"
        case .kicks: return "kick"
        case .banks: return "bank"
        case .safeties: return "safety"
        case .breaks: return "break"
        case .lags: return "lag"
        case .attempts: return "attempt"
        case .reps: return "rep"
        case .routes: return "route"
        case .caroms: return "carom"
        case .jumps: return "jump"
        }
    }

    var plural: String {
        switch self {
        case .balls: return "balls"
        case .shots: return "shots"
        case .targets: return "targets"
        case .kicks: return "kicks"
        case .banks: return "banks"
        case .safeties: return "safeties"
        case .breaks: return "breaks"
        case .lags: return "lags"
        case .attempts: return "attempts"
        case .reps: return "reps"
        case .routes: return "routes"
        case .caroms: return "caroms"
        case .jumps: return "jumps"
        }
    }

    var progressTitle: String {
        switch self {
        case .balls: return "Potted"
        case .breaks: return "Breaks"
        default: return "Completed"
        }
    }

    func text(for count: Int) -> String {
        "\(count) \(count == 1 ? singular : plural)"
    }

    func rangeText(min: Int, max: Int) -> String {
        min == max ? text(for: min) : "\(min)-\(max) \(plural)"
    }
}

enum DrillDifficultyLevel: String, Codable, CaseIterable, Hashable {
    case beginner
    case easy
    case standard
    case hard
    case expert

    var label: String {
        switch self {
        case .beginner: return "Beginner"
        case .easy: return "Easy"
        case .standard: return "Standard"
        case .hard: return "Hard"
        case .expert: return "Expert"
        }
    }
}

struct DrillDifficulty: Identifiable, Codable, Hashable {
    var level: DrillDifficultyLevel
    var ballCount: Int
    var constraint: String

    var id: String { level.rawValue }
}

enum DrillLibrary {
    static let fargoSkills = ["Potting", "Position", "Pattern", "Runout", "Overall"]

    static let templates: [DrillTemplate] = DrillLibraryCatalog.templates

    static func template(id: String?) -> DrillTemplate? {
        guard let id else { return nil }
        return templates.first { $0.id == id }
    }
}
