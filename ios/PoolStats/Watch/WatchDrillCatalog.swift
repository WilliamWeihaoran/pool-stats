import SwiftUI

enum WatchDrillCatalog {
    static let fallbackTemplates: [WatchDrillTemplatePayload] = [
        template(id: "l_drill", title: "L Drill", counts: [5, 7, 9, 11, 15]),
        template(id: "one_side_pattern", title: "Line drill", counts: [4, 6, 8, 10, 12]),
        template(id: "stop_shot_ladder", title: "Stop-shot progressive", counts: [3, 5, 7, 9, 10]),
        template(id: "centerline_control", title: "Circle control", counts: [4, 6, 8, 10, 12]),
        template(id: "rail_avoidance", title: "1-10 control ladder", counts: [3, 4, 5, 7, 10]),
        template(id: "open_table_runout", title: "Runout drill mini", counts: [3, 4, 5, 6, 7]),
        template(id: "cut_shot_progressive", title: "Cut-shot progressive", counts: [5, 7, 10, 12, 15]),
        template(id: "follow_progressive", title: "Follow progressive", counts: [3, 5, 7, 9, 10]),
        template(id: "draw_progressive", title: "Draw progressive", counts: [3, 5, 7, 9, 10]),
        template(id: "stun_tangent_line", title: "Stun tangent-line drill", counts: [4, 6, 8, 10, 12]),
        template(id: "wagon_wheel", title: "Wagon-wheel position", counts: [4, 6, 8, 10, 12]),
        template(id: "target_pool", title: "Target-pool position", counts: [4, 6, 8, 10, 12]),
        template(id: "rail_cut_progressive", title: "Rail-cut progressive", counts: [4, 6, 8, 10, 12]),
        template(id: "spot_shot_challenge", title: "Spot-shot challenge", counts: [5, 7, 10, 12, 15]),
        template(id: "long_straight_in", title: "Long straight-in", counts: [4, 6, 8, 10, 12]),
        template(id: "thin_cut_ladder", title: "Thin-cut ladder", counts: [4, 6, 8, 10, 12]),
        template(id: "back_cut_ladder", title: "Back-cut ladder", counts: [4, 6, 8, 10, 12]),
        template(id: "no_rail_pattern", title: "No-rail pattern", counts: [3, 4, 5, 6, 7]),
        template(id: "three_ball_ghost", title: "3-ball ghost", counts: [3, 4, 5, 6, 7]),
        template(id: "nine_ball_ghost", title: "9-ball ghost mini", counts: [3, 4, 5, 7, 9]),
        template(id: "eight_ball_pattern", title: "8-ball pattern mini", counts: [4, 5, 6, 7, 8]),
        template(id: "placement_pool_challenge", title: "Placement challenge", counts: [3, 4, 5, 6, 7]),
        template(id: "rds_break_run", title: "RDS break-and-run", counts: [3, 4, 5, 7, 9]),
        template(id: "equal_offense", title: "Equal Offense", counts: [5, 7, 10, 12, 15]),
        template(id: "fargo_rotation", title: "Fargo rotation drill", counts: [5, 7, 9, 12, 15]),
        template(id: "fifteen_ball_rotation", title: "15-ball rotation", counts: [6, 8, 10, 12, 15]),
        template(id: "hopkins_q_skills", title: "Hopkins Q Skills", counts: [5, 7, 10, 12, 15]),
        template(id: "one_rail_kick", title: "One-rail kick ladder", counts: [3, 5, 7, 9, 10]),
        template(id: "cross_side_bank", title: "Cross-side bank ladder", counts: [3, 5, 7, 9, 10]),
        template(id: "safety_hide", title: "Hide-the-ball safety", counts: [3, 5, 7, 9, 10]),
        template(id: "break_control", title: "Break control", counts: [5, 7, 10, 12, 15]),
        template(id: "center_ball_stroke", title: "Center-ball stroke", counts: [5, 7, 10, 12, 15]),
        template(id: "side_spin_ladder", title: "Sidespin ladder", counts: [3, 5, 7, 9, 10]),
        template(id: "carom_touch", title: "Carom touch drill", counts: [3, 5, 7, 9, 10]),
        template(id: "jump_escape_basic", title: "Jump escape basics", counts: [3, 5, 7, 9, 10]),

        template(id: "t_drill", title: "T Drill", counts: [5, 7, 9, 11, 15]),
        template(id: "down_rail_drill", title: "Down-the-rail drill", counts: [4, 6, 8, 10, 15]),
        template(id: "spot_rotation_drill", title: "Spot rotation drill", counts: [3, 5, 7, 9, 10]),
        template(id: "inside_outside_english", title: "Inside-outside English", counts: [3, 5, 7, 9, 10]),
        template(id: "side_pocket_cut_ladder", title: "Side-pocket cut ladder", counts: [3, 5, 7, 9, 10]),
        template(id: "brainwashing_no_rail", title: "Brainwashing no-rail", counts: [3, 4, 5, 6, 7]),
        template(id: "ghost_ball_aiming", title: "Ghost-ball aiming", counts: [5, 7, 10, 12, 15]),
        template(id: "vision_center_alignment", title: "Vision-center alignment", counts: [5, 7, 10, 12, 15]),
        template(id: "up_down_speed_control", title: "Up-and-down speed", counts: [4, 6, 8, 10, 12]),
        template(id: "cross_line_speed", title: "Cross-line speed", counts: [4, 6, 8, 10, 12]),
        template(id: "clock_system_spin", title: "Clock-system spin", counts: [3, 5, 7, 9, 10]),
        template(id: "gearing_outside_spin", title: "Gearing outside spin", counts: [3, 5, 7, 9, 10]),
        template(id: "one_rail_target_pool", title: "One-rail target pool", counts: [3, 5, 7, 9, 10]),
        template(id: "two_rail_target_pool", title: "Two-rail target pool", counts: [3, 5, 7, 9, 10]),
        template(id: "three_rail_target_pool", title: "Three-rail target pool", counts: [3, 5, 7, 9, 10])
    ]

    static func label(for raw: String) -> String {
        switch raw {
        case "beginner": return "Beginner"
        case "easy": return "Easy"
        case "standard": return "Standard"
        case "hard": return "Hard"
        case "expert": return "Expert"
        default: return "Drill"
        }
    }

    static func color(for raw: String) -> Color {
        switch raw {
        case "beginner": return Color(red: 0.37, green: 0.92, blue: 0.83)
        case "easy": return Color.teal
        case "standard": return Color(red: 0.98, green: 0.75, blue: 0.25)
        case "hard": return Color.orange
        case "expert": return Color(red: 0.97, green: 0.44, blue: 0.44)
        default: return .white.opacity(0.72)
        }
    }

    static func skillColor(_ tag: String) -> Color {
        switch tag.lowercased() {
        case "potting": return Color(red: 0.97, green: 0.44, blue: 0.44)
        case "position": return Color(red: 0.38, green: 0.65, blue: 0.98)
        case "pattern": return Color(red: 0.37, green: 0.92, blue: 0.83)
        case "runout": return Color(red: 0.68, green: 0.54, blue: 0.98)
        default: return .white.opacity(0.72)
        }
    }

    static func ballCount(template: WatchDrillTemplatePayload?, difficulty: String) -> Int {
        template?.difficultyLevels.first(where: { $0.level == difficulty })?.ballCount
            ?? template?.difficultyLevels.first(where: { $0.level == "standard" })?.ballCount
            ?? 5
    }

    private static func template(id: String, title: String, counts: [Int]) -> WatchDrillTemplatePayload {
        let levels = ["beginner", "easy", "standard", "hard", "expert"]
        let labels = ["Beginner", "Easy", "Standard", "Hard", "Expert"]
        return WatchDrillTemplatePayload(
            id: id,
            title: title,
            details: "",
            countUnit: countUnit(for: id).rawValue,
            difficultyLevels: Array(zip(Array(zip(levels, labels)), counts)).map { pair, count in
                WatchDrillTemplateDifficultyPayload(level: pair.0, label: pair.1, ballCount: count, constraint: "")
            }
        )
    }

    private static func countUnit(for id: String) -> WatchDrillCountUnit {
        switch id {
        case "stop_shot_ladder",
             "cut_shot_progressive",
             "follow_progressive",
             "draw_progressive",
             "stun_tangent_line",
             "target_pool",
             "rail_cut_progressive",
             "spot_shot_challenge",
             "long_straight_in",
             "thin_cut_ladder",
             "back_cut_ladder",
             "center_ball_stroke",
             "side_spin_ladder",
             "inside_outside_english",
             "side_pocket_cut_ladder",
             "ghost_ball_aiming",
             "vision_center_alignment",
             "gearing_outside_spin":
            return .shots
        case "wagon_wheel":
            return .targets
        case "one_rail_kick":
            return .kicks
        case "cross_side_bank":
            return .banks
        case "safety_hide":
            return .safeties
        case "break_control":
            return .breaks
        case "carom_touch":
            return .caroms
        case "jump_escape_basic":
            return .jumps
        case "up_down_speed_control":
            return .lags
        case "cross_line_speed":
            return .attempts
        case "clock_system_spin":
            return .reps
        case "one_rail_target_pool",
             "two_rail_target_pool",
             "three_rail_target_pool":
            return .routes
        default:
            return .balls
        }
    }
}
