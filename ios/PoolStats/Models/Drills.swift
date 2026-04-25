import Foundation

struct DrillTemplate: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var kind: DrillKind
    var pictureID: String
    var description: String
    var primarySkills: [String]
    var secondarySkills: [String]
    var difficultyLevels: [DrillDifficulty]
    var instructions: [String]

    var primarySkill: String { primarySkills.first ?? "Overall" }
    var subskills: [String] { secondarySkills }

    var standardDifficulty: DrillDifficulty {
        difficultyLevels.first(where: { $0.level == .standard }) ?? difficultyLevels[0]
    }

    var difficultyRangeText: String {
        guard let minBalls = difficultyLevels.map(\.ballCount).min(),
              let maxBalls = difficultyLevels.map(\.ballCount).max() else { return "Adaptive" }
        return minBalls == maxBalls ? "\(minBalls) balls" : "\(minBalls)-\(maxBalls) balls"
    }
}

enum DrillKind: String, Codable, Hashable {
    case staticLayout
    case randomLayout
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

    static let templates: [DrillTemplate] = [
        DrillTemplate(
            id: "l_drill",
            title: "L Drill",
            kind: .staticLayout,
            pictureID: "l_drill",
            description: "A classic fixed-pattern drill for learning short routes, pocket speed, and repeatable cue-ball control around the corner of the table.",
            primarySkills: ["Position", "Pattern", "Potting"],
            secondarySkills: ["Fundamentals", "Small-area control", "Pocket speed"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 4, constraint: "Four-ball mini L. Ball in hand after a miss."),
                DrillDifficulty(level: .easy, ballCount: 5, constraint: "Five balls. Restart only when the cue-ball route is lost."),
                DrillDifficulty(level: .standard, ballCount: 7, constraint: "Seven balls. Run the L in order without moving the cue ball by hand."),
                DrillDifficulty(level: .hard, ballCount: 8, constraint: "Eight balls. Strict order and no bailout safety."),
                DrillDifficulty(level: .expert, ballCount: 9, constraint: "Full L. Strict order, tight speed, and no side spin unless required.")
            ],
            instructions: [
                "Place the balls in an L shape near one corner.",
                "Pot the balls in order while staying in the small scoring area.",
                "Log a miss when you lose the route or fail to pot the next ball."
            ]
        ),
        DrillTemplate(
            id: "one_side_pattern",
            title: "One-side pattern",
            kind: .randomLayout,
            pictureID: "one_side_pattern",
            description: "Scatter balls on one side of the table, pot them in order, and keep the cue ball from crossing the centerline.",
            primarySkills: ["Pattern", "Position"],
            secondarySkills: ["Center-ball", "Small-area control", "Speed control"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three balls, center-ball only, cue ball may not cross the centerline."),
                DrillDifficulty(level: .easy, ballCount: 4, constraint: "Four balls, center-ball only, cue ball may not cross the centerline."),
                DrillDifficulty(level: .standard, ballCount: 5, constraint: "Five balls, center-ball only, strict no-crossing rule."),
                DrillDifficulty(level: .hard, ballCount: 6, constraint: "Six balls, no side spin, no crossing, no bumping object balls."),
                DrillDifficulty(level: .expert, ballCount: 7, constraint: "Seven balls, same-side only, call the full route before shooting.")
            ],
            instructions: [
                "Scatter the selected number of balls randomly on one side of the table.",
                "Choose the order before the first shot.",
                "No side spin; mark a miss if the cue ball crosses the centerline."
            ]
        ),
        DrillTemplate(
            id: "stop_shot_ladder",
            title: "Stop-shot ladder",
            kind: .staticLayout,
            pictureID: "stop_shot_ladder",
            description: "A straight-shot fundamentals ladder for learning clean stop-shot contact at increasing distances.",
            primarySkills: ["Potting", "Overall"],
            secondarySkills: ["Stop shot", "Speed control", "Fundamentals"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three short stop shots. Count only clean stops."),
                DrillDifficulty(level: .easy, ballCount: 4, constraint: "Four distances. Cue ball must stop within a ball width."),
                DrillDifficulty(level: .standard, ballCount: 5, constraint: "Five distances. Cue ball must stop within a chalk width."),
                DrillDifficulty(level: .hard, ballCount: 6, constraint: "Six distances. No drift and no rail contact."),
                DrillDifficulty(level: .expert, ballCount: 7, constraint: "Seven distances. Alternate soft and firm stop shots cleanly.")
            ],
            instructions: [
                "Shoot each object ball from nearest to farthest.",
                "The cue ball should stop dead after contact.",
                "Move farther only after a clean stop."
            ]
        ),
        DrillTemplate(
            id: "centerline_control",
            title: "Centerline control",
            kind: .randomLayout,
            pictureID: "centerline_control",
            description: "Pot random object balls while returning the cue ball to a central lane after each shot.",
            primarySkills: ["Position", "Pattern"],
            secondarySkills: ["Centerline routes", "Speed control", "Cue-ball discipline"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three balls. Cue ball must finish in the center lane."),
                DrillDifficulty(level: .easy, ballCount: 4, constraint: "Four balls. Center-lane finish after every shot."),
                DrillDifficulty(level: .standard, ballCount: 5, constraint: "Five balls. Center-lane finish and no accidental contacts."),
                DrillDifficulty(level: .hard, ballCount: 6, constraint: "Six balls. Call the next zone before each shot."),
                DrillDifficulty(level: .expert, ballCount: 7, constraint: "Seven balls. Center-lane finish every shot with one planned route."
                )
            ],
            instructions: [
                "Place balls randomly across the table.",
                "Pot in the planned order.",
                "Score success only when each cue-ball finish lands in the center lane."
            ]
        ),
        DrillTemplate(
            id: "rail_avoidance",
            title: "Rail-avoidance pattern",
            kind: .randomLayout,
            pictureID: "rail_avoidance",
            description: "Clear a small layout while keeping the cue ball out of dangerous rail zones.",
            primarySkills: ["Position", "Pattern"],
            secondarySkills: ["Rail avoidance", "Cue-ball routes", "Angle control"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 3, constraint: "Three balls. Cue ball may touch a rail but may not finish in a red zone."),
                DrillDifficulty(level: .easy, ballCount: 4, constraint: "Four balls. No finish near either long rail."),
                DrillDifficulty(level: .standard, ballCount: 5, constraint: "Five balls. No rail-zone finishes and no accidental contacts."),
                DrillDifficulty(level: .hard, ballCount: 6, constraint: "Six balls. Keep cue-ball routes inside the central safe lane."),
                DrillDifficulty(level: .expert, ballCount: 7, constraint: "Seven balls. Call the route and never finish in a rail zone.")
            ],
            instructions: [
                "Scatter the balls in the safe central area.",
                "Plan routes that keep the cue ball away from the long rails.",
                "Mark a miss if the cue ball finishes in a forbidden zone."
            ]
        ),
        DrillTemplate(
            id: "open_table_runout",
            title: "Open-table runout mini",
            kind: .randomLayout,
            pictureID: "open_table_runout",
            description: "Create a compact open layout with no clusters, then solve the runout in numerical order.",
            primarySkills: ["Runout", "Pattern", "Potting"],
            secondarySkills: ["Planning", "Shot selection", "Route discipline"],
            difficultyLevels: [
                DrillDifficulty(level: .beginner, ballCount: 4, constraint: "Four open balls. Ball in hand before the first shot."),
                DrillDifficulty(level: .easy, ballCount: 5, constraint: "Five open balls. Ball in hand before the first shot."),
                DrillDifficulty(level: .standard, ballCount: 6, constraint: "Six open balls. Strict order and no bailout safeties."),
                DrillDifficulty(level: .hard, ballCount: 7, constraint: "Seven open balls. Call the final three-ball pattern first."),
                DrillDifficulty(level: .expert, ballCount: 8, constraint: "Eight open balls. One planned route, no extra ball in hand.")
            ],
            instructions: [
                "Create an open layout with no clusters.",
                "Pot balls in numerical order.",
                "Focus on planning three balls ahead."
            ]
        )
    ]

    static func template(id: String?) -> DrillTemplate? {
        guard let id else { return nil }
        return templates.first { $0.id == id }
    }
}
