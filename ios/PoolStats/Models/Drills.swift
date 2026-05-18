import Foundation

private func localizedDrillText(_ text: String) -> String {
    NSLocalizedString(text, comment: "")
}

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

    var localizedTitle: String { localizedDrillText(title) }
    var localizedDescription: String { localizedDrillText(description) }
    var localizedPrimarySkills: [String] { primarySkills.map(localizedDrillText) }
    var localizedSecondarySkills: [String] { secondarySkills.map(localizedDrillText) }
    var localizedInstructions: [String] { instructions.map(localizedDrillText) }
    var searchableText: String {
        ([title, description] + primarySkills + secondarySkills + [localizedTitle, localizedDescription] + localizedPrimarySkills + localizedSecondarySkills)
            .joined(separator: " ")
    }

    var primarySkill: String { localizedPrimarySkills.first ?? NSLocalizedString("Overall", comment: "") }
    var subskills: [String] { localizedSecondarySkills }

    var standardDifficulty: DrillDifficulty {
        difficultyLevels.first(where: { $0.level == .standard })
            ?? difficultyLevels.first
            ?? DrillDifficulty(level: .standard, ballCount: 5, constraint: "")
    }

    var difficultyRangeText: String {
        guard let minCount = difficultyLevels.map(\.ballCount).min(),
              let maxCount = difficultyLevels.map(\.ballCount).max() else { return NSLocalizedString("Adaptive", comment: "") }
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
        case .balls: return NSLocalizedString("Balls", comment: "")
        case .shots: return NSLocalizedString("Shots", comment: "")
        case .targets: return NSLocalizedString("Targets", comment: "")
        case .kicks: return NSLocalizedString("Kicks", comment: "")
        case .banks: return NSLocalizedString("Banks", comment: "")
        case .safeties: return NSLocalizedString("Safeties", comment: "")
        case .breaks: return NSLocalizedString("Breaks", comment: "")
        case .lags: return NSLocalizedString("Lags", comment: "")
        case .attempts: return NSLocalizedString("Attempts", comment: "")
        case .reps: return NSLocalizedString("Reps", comment: "")
        case .routes: return NSLocalizedString("Routes", comment: "")
        case .caroms: return NSLocalizedString("Caroms", comment: "")
        case .jumps: return NSLocalizedString("Jumps", comment: "")
        }
    }

    var singular: String {
        switch self {
        case .balls: return NSLocalizedString("ball", comment: "")
        case .shots: return NSLocalizedString("shot", comment: "")
        case .targets: return NSLocalizedString("target", comment: "")
        case .kicks: return NSLocalizedString("kick", comment: "")
        case .banks: return NSLocalizedString("bank", comment: "")
        case .safeties: return NSLocalizedString("safety", comment: "")
        case .breaks: return NSLocalizedString("break", comment: "")
        case .lags: return NSLocalizedString("lag", comment: "")
        case .attempts: return NSLocalizedString("attempt", comment: "")
        case .reps: return NSLocalizedString("rep", comment: "")
        case .routes: return NSLocalizedString("route", comment: "")
        case .caroms: return NSLocalizedString("carom", comment: "")
        case .jumps: return NSLocalizedString("jump", comment: "")
        }
    }

    var plural: String {
        switch self {
        case .balls: return NSLocalizedString("balls", comment: "")
        case .shots: return NSLocalizedString("shots", comment: "")
        case .targets: return NSLocalizedString("targets", comment: "")
        case .kicks: return NSLocalizedString("kicks", comment: "")
        case .banks: return NSLocalizedString("banks", comment: "")
        case .safeties: return NSLocalizedString("safeties", comment: "")
        case .breaks: return NSLocalizedString("breaks", comment: "")
        case .lags: return NSLocalizedString("lags", comment: "")
        case .attempts: return NSLocalizedString("attempts", comment: "")
        case .reps: return NSLocalizedString("reps", comment: "")
        case .routes: return NSLocalizedString("routes", comment: "")
        case .caroms: return NSLocalizedString("caroms", comment: "")
        case .jumps: return NSLocalizedString("jumps", comment: "")
        }
    }

    var progressTitle: String {
        switch self {
        case .balls: return NSLocalizedString("Potted", comment: "")
        case .breaks: return NSLocalizedString("Breaks", comment: "")
        default: return NSLocalizedString("Completed", comment: "")
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
        case .beginner: return NSLocalizedString("Beginner", comment: "")
        case .easy: return NSLocalizedString("Easy", comment: "")
        case .standard: return NSLocalizedString("Standard", comment: "")
        case .hard: return NSLocalizedString("Hard", comment: "")
        case .expert: return NSLocalizedString("Expert", comment: "")
        }
    }
}

struct DrillDifficulty: Identifiable, Codable, Hashable {
    var level: DrillDifficultyLevel
    var ballCount: Int
    var constraint: String

    var id: String { level.rawValue }
    var localizedConstraint: String { localizedDrillText(constraint) }

    var summaryText: String {
        "\(level.label) · \(ballCount)"
    }
}

enum DrillLibrary {
    static let fargoSkills = ["Potting", "Position", "Pattern", "Runout", "Overall"]

    static let templates: [DrillTemplate] = DrillLibraryCatalog.templates

    static func template(id: String?) -> DrillTemplate? {
        guard let id else { return nil }
        return templates.first { $0.id == id }
    }
}
