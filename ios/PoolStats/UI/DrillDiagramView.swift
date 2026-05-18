import SwiftUI

struct DrillPictureExpandedView: View {
    @Environment(\.dismiss) private var dismiss
    let template: DrillTemplate
    let difficulty: DrillDifficulty

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(template.localizedTitle)
                            .font(.headline.weight(.bold))
                            .foregroundColor(Theme.text)
                        Text(template.difficultySummary(difficulty))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(difficultyColor(for: difficulty.level))
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.black))
                            .foregroundColor(Theme.text)
                            .frame(width: 34, height: 34)
                            .background(Theme.panel2)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)

                DrillPictureView(template: template, difficulty: difficulty)
                    .aspectRatio(1.9, contentMode: .fit)
                    .padding(.horizontal, 14)

                Spacer(minLength: 0)
            }
            .padding(.top, 18)
        }
    }
}

struct DrillThumbnail: View {
    let template: DrillTemplate
    var body: some View {
        DrillPictureView(template: template, difficulty: template.standardDifficulty)
            .allowsHitTesting(false)
    }
}

struct DrillPictureView: View {
    let template: DrillTemplate
    let difficulty: DrillDifficulty

    private var ballCount: Int { difficulty.ballCount }
    private var level: DrillDifficultyLevel { difficulty.level }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                tableBackground
                tableGuides(in: size)
                railDiamonds(in: size)
                pockets(in: size)
                drillZones(for: template, level: level, in: size)
                ForEach(balls(for: template, ballCount: ballCount, level: level)) { ball in
                    ballView(ball, in: size)
                }
            }
        }
    }

    private var tableBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(LinearGradient(colors: [Color(red: 0.02, green: 0.31, blue: 0.24), Color(red: 0.01, green: 0.18, blue: 0.16)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.13), lineWidth: 2).padding(5))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.34), lineWidth: 6).padding(4))
    }

    private func tableGuides(in size: CGSize) -> some View {
        let verticals: [Double] = [0.25, 0.50, 0.75]
        let horizontals: [Double] = [0.25, 0.50, 0.75]
        let insetX = size.width * 0.08
        let insetY = size.height * 0.13

        return ZStack {
            ForEach(verticals, id: \.self) { x in
                Path { path in
                    path.move(to: CGPoint(x: size.width * x, y: insetY))
                    path.addLine(to: CGPoint(x: size.width * x, y: size.height - insetY))
                }
                .stroke(Color.white.opacity(x == 0.50 ? 0.10 : 0.065), style: StrokeStyle(lineWidth: 0.8, dash: [4, 8]))
            }

            ForEach(horizontals, id: \.self) { y in
                Path { path in
                    path.move(to: CGPoint(x: insetX, y: size.height * y))
                    path.addLine(to: CGPoint(x: size.width - insetX, y: size.height * y))
                }
                .stroke(Color.white.opacity(y == 0.50 ? 0.10 : 0.065), style: StrokeStyle(lineWidth: 0.8, dash: [4, 8]))
            }
        }
    }

    private func railDiamonds(in size: CGSize) -> some View {
        let horizontalMarks: [Double] = [0.19, 0.32, 0.68, 0.81]
        let verticalMarks: [Double] = [0.27, 0.50, 0.73]
        let diamondSize = max(3.5, min(size.width, size.height) * 0.025)
        let horizontalY = max(8, size.height * 0.09)
        let verticalX = max(8, size.width * 0.045)

        return ZStack {
            ForEach(horizontalMarks, id: \.self) { x in
                diamond(size: diamondSize)
                    .position(x: size.width * x, y: horizontalY)
                diamond(size: diamondSize)
                    .position(x: size.width * x, y: size.height - horizontalY)
            }

            ForEach(verticalMarks, id: \.self) { y in
                diamond(size: diamondSize)
                    .position(x: verticalX, y: size.height * y)
                diamond(size: diamondSize)
                    .position(x: size.width - verticalX, y: size.height * y)
            }
        }
    }

    private func diamond(size: CGFloat) -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.30))
            .frame(width: size, height: size)
            .rotationEffect(.degrees(45))
            .shadow(color: Color.black.opacity(0.12), radius: 1, x: 0, y: 1)
    }

    private func pockets(in size: CGSize) -> some View {
        let insetX = max(13, size.width * 0.045)
        let insetY = max(12, size.height * 0.08)
        let radius = max(5, min(size.width, size.height) * 0.04)
        let points = [
            CGPoint(x: insetX, y: insetY), CGPoint(x: size.width / 2, y: insetY * 0.72), CGPoint(x: size.width - insetX, y: insetY),
            CGPoint(x: insetX, y: size.height - insetY), CGPoint(x: size.width / 2, y: size.height - insetY * 0.72), CGPoint(x: size.width - insetX, y: size.height - insetY)
        ]
        return ForEach(Array(points.enumerated()), id: \.offset) { _, point in
            Circle().fill(Color.black.opacity(0.88)).frame(width: radius * 2, height: radius * 2).position(point)
        }
    }

    @ViewBuilder
    private func drillZones(for template: DrillTemplate, level: DrillDifficultyLevel, in size: CGSize) -> some View {
        let step = difficultyStep(level)
        let targetSize = max(0.12, 0.28 - step * 0.035)
        let targetHeight = max(0.12, 0.24 - step * 0.028)

        switch template.id {
        case "l_drill":
            zone(x: 0.15, y: 0.17, w: 0.18, h: 0.56, label: "Vertical leg", color: Theme.teal, in: size)
            zone(x: 0.24, y: 0.62, w: 0.58, h: 0.20, label: "Foot leg", color: Theme.teal, in: size)
            route([(0.20, 0.70), (0.26, 0.54), (0.26, 0.28), (0.56, 0.70), (0.84, 0.70), (0.91, 0.88)], color: Theme.teal, in: size)
            spotTarget(x: 0.91, y: 0.88, label: "Same corner", color: Theme.teal, in: size)
        case "one_side_pattern":
            tableLine(from: (0.40, 0.18), to: (0.62, 0.78), color: Theme.green, in: size)
            zone(x: 0.48, y: 0.18, w: 0.24, h: 0.60, label: "Right side", color: Theme.green, in: size)
            route([(0.34, 0.78), (0.46, 0.24), (0.54, 0.42), (0.62, 0.60), (0.52, 0.76)], color: Theme.green, in: size)
        case "centerline_control":
            Circle()
                .fill(Theme.teal.opacity(0.10))
                .overlay(Circle().stroke(Theme.teal.opacity(0.40), style: StrokeStyle(lineWidth: 1, dash: [6, 5])))
                .frame(width: size.width * max(0.32, 0.54 - step * 0.045), height: size.width * max(0.32, 0.54 - step * 0.045))
                .position(x: size.width * 0.50, y: size.height * 0.52)
            route([(0.50, 0.52), (0.62, 0.38), (0.45, 0.64), (0.34, 0.46)], color: Theme.teal, in: size)
        case "rail_avoidance":
            zone(x: 0.10, y: 0.26, w: 0.22, h: 0.48, label: "Odd row", color: Theme.blue, in: size)
            zone(x: 0.68, y: 0.26, w: 0.22, h: 0.48, label: "Even row", color: Theme.purple, in: size)
            route([(0.18, 0.80), (0.24, 0.33), (0.76, 0.43), (0.24, 0.53), (0.76, 0.63)], color: Theme.purple, in: size)
        case "open_table_runout":
            zone(x: 0.18, y: 0.20, w: 0.64, h: 0.58, label: "Open layout", color: Theme.green, in: size)
            route([(0.25, 0.72), (0.38, 0.34), (0.56, 0.58), (0.72, 0.36)], color: Theme.green, in: size)
        case "three_ball_ghost":
            route([(0.26, 0.72), (0.34, 0.40), (0.56, 0.58), (0.72, 0.34)], color: Theme.green, in: size)
        case "nine_ball_ghost":
            route([(0.24, 0.72), (0.34, 0.58), (0.48, 0.35), (0.62, 0.62), (0.76, 0.38)], color: Theme.amber, in: size)
            spotTarget(x: 0.34, y: 0.58, label: "Next", color: Theme.amber, in: size)
        case "fargo_rotation":
            zone(x: 0.14, y: 0.18, w: 0.72, h: 0.62, label: "Rotation score", color: Theme.amber, in: size)
            route([(0.24, 0.72), (0.34, 0.58), (0.48, 0.35), (0.62, 0.62), (0.76, 0.38), (0.54, 0.48)], color: Theme.amber, in: size)
        case "fifteen_ball_rotation":
            zone(x: 0.10, y: 0.15, w: 0.80, h: 0.68, label: "Full-table rotation", color: Theme.red, in: size)
            route([(0.22, 0.74), (0.30, 0.58), (0.44, 0.32), (0.60, 0.62), (0.78, 0.38), (0.68, 0.78)], color: Theme.red, in: size)
        case "eight_ball_pattern":
            route([(0.25, 0.72), (0.36, 0.38), (0.58, 0.54), (0.72, 0.30)], color: Theme.purple, in: size)
            zone(x: 0.60, y: 0.20, w: targetSize, h: targetHeight, label: "8-ball key", color: Theme.purple, in: size)
        case "placement_pool_challenge":
            route([(0.28, 0.70), (0.42, 0.42), (0.56, 0.60), (0.72, 0.42)], color: Theme.blue, in: size)
            zone(x: 0.50, y: 0.25, w: targetSize, h: targetHeight, label: "Preset route", color: Theme.blue, in: size)
        case "rds_break_run":
            zone(x: 0.28, y: 0.18, w: 0.44, h: 0.48, label: "Break spread", color: Theme.green, in: size)
            route([(0.30, 0.74), (0.44, 0.34), (0.62, 0.48), (0.76, 0.28)], color: Theme.green, in: size)
        case "equal_offense":
            zone(x: 0.16, y: 0.18, w: 0.68, h: 0.62, label: "Score until miss", color: Theme.teal, in: size)
            route([(0.20, 0.76), (0.32, 0.58), (0.48, 0.48), (0.66, 0.56), (0.78, 0.44)], color: Theme.teal, in: size)
        case "hopkins_q_skills":
            zone(x: 0.14, y: 0.16, w: 0.72, h: 0.64, label: "Open-table inning", color: Theme.green, in: size)
            route([(0.20, 0.76), (0.24, 0.26), (0.42, 0.36), (0.60, 0.24), (0.78, 0.44)], color: Theme.green, in: size)
        case "no_rail_pattern":
            zone(x: 0.18, y: 0.24, w: 0.64, h: 0.52, label: "No rails", color: Theme.teal, in: size)
            route([(0.42, 0.68), (0.34, 0.42), (0.54, 0.38), (0.66, 0.50)], color: Theme.teal, in: size)
        case "cut_shot_progressive":
            route([(progressiveCueX(level), 0.70), (0.36, 0.42), (0.14, 0.16)], color: Theme.amber, in: size)
            zone(x: 0.52, y: 0.58, w: targetSize, h: targetHeight, label: "Move CB back", color: Theme.amber, in: size)
        case "follow_progressive":
            tableLine(from: (progressiveCueX(level), 0.50), to: (0.14, 0.50), color: Theme.teal, in: size)
            route([(progressiveCueX(level), 0.50), (0.32, 0.50), (0.14, 0.50)], color: Theme.amber, in: size)
            route([(0.32, 0.50), (0.50, 0.50), (0.68, 0.50)], color: Theme.green, in: size)
            zone(x: 0.60, y: 0.38, w: targetSize, h: targetHeight, label: "Follow target", color: Theme.green, in: size)
        case "draw_progressive":
            tableLine(from: (progressiveCueX(level), 0.50), to: (0.14, 0.50), color: Theme.teal, in: size)
            route([(progressiveCueX(level), 0.50), (0.32, 0.50), (0.14, 0.50)], color: Theme.amber, in: size)
            route([(0.32, 0.50), (progressiveCueX(level), 0.50), (0.74, 0.50)], color: Theme.blue, in: size)
            zone(x: 0.58, y: 0.38, w: targetSize, h: targetHeight, label: "Draw back", color: Theme.blue, in: size)
        case "stop_shot_ladder":
            tableLine(from: (progressiveCueX(level), 0.50), to: (0.14, 0.50), color: Theme.teal, in: size)
            route([(progressiveCueX(level), 0.50), (0.32, 0.50), (0.14, 0.50)], color: Theme.amber, in: size)
            spotTarget(x: 0.32, y: 0.50, label: "CB stop", color: Theme.amber, in: size)
        case "stun_tangent_line":
            route([(0.64 + step * 0.025, 0.66), (0.38, 0.44), (0.14, 0.16)], color: Theme.amber, in: size)
            route([(0.38, 0.44), (0.58, 0.62), (0.72, 0.34)], color: Theme.blue, in: size)
            zone(x: 0.50, y: 0.22, w: targetSize, h: targetHeight, label: "Tangent", color: Theme.blue, in: size)
        case "rail_cut_progressive":
            zone(x: 0.09, y: 0.13, w: 0.18, h: 0.72, label: "Rail ball", color: Theme.blue, in: size)
            route([(0.62, 0.72), (0.23, 0.26), (0.14, 0.16)], color: Theme.blue, in: size)
            zone(x: 0.44, y: 0.58, w: targetSize, h: targetHeight, label: "CB finish", color: Theme.teal, in: size)
        case "spot_shot_challenge":
            tableLine(from: (0.14, 0.76), to: (0.86, 0.76), color: Theme.blue, in: size)
            route([(0.42, 0.78), (0.50, 0.30), (0.14, 0.16)], color: Theme.amber, in: size)
            spotTarget(x: 0.50, y: 0.30, label: "Spot", color: Theme.amber, in: size)
        case "long_straight_in":
            tableLine(from: (0.74, 0.50), to: (0.14, 0.50), color: Theme.teal, in: size)
            route([(0.74, 0.50), (0.34, 0.50), (0.14, 0.50)], color: Theme.teal, in: size)
            zone(x: 0.54, y: 0.40, w: targetSize, h: targetHeight, label: "No drift", color: Theme.teal, in: size)
        case "thin_cut_ladder":
            route([(0.72, 0.72), (0.38, 0.46), (0.14, 0.16)], color: Theme.red, in: size)
            zone(x: 0.56, y: 0.58, w: targetSize, h: targetHeight, label: "Thinner angle", color: Theme.red, in: size)
        case "back_cut_ladder":
            route([(0.28, 0.72), (0.58, 0.42), (0.86, 0.16)], color: Theme.amber, in: size)
            route([(0.58, 0.42), (0.34, 0.66)], color: Theme.red, in: size)
            zone(x: 0.18, y: 0.58, w: targetSize, h: targetHeight, label: "Avoid scratch", color: Theme.red, in: size)
        case "wagon_wheel":
            Circle()
                .fill(Theme.purple.opacity(0.08))
                .overlay(Circle().stroke(Theme.purple.opacity(0.34), style: StrokeStyle(lineWidth: 1, dash: [5, 5])))
                .frame(width: size.width * max(0.40, 0.66 - step * 0.045), height: size.width * max(0.40, 0.66 - step * 0.045))
                .position(x: size.width * 0.50, y: size.height * 0.52)
            tableLine(from: (0.52, 0.55), to: (0.30, 0.22), color: Theme.purple, in: size)
            tableLine(from: (0.52, 0.55), to: (0.74, 0.26), color: Theme.purple, in: size)
            tableLine(from: (0.52, 0.55), to: (0.78, 0.72), color: Theme.purple, in: size)
            tableLine(from: (0.52, 0.55), to: (0.28, 0.72), color: Theme.purple, in: size)
            route([(0.34, 0.50), (0.52, 0.55), (0.72, 0.28)], color: Theme.purple, in: size)
        case "target_pool":
            route([(0.62, 0.68), (0.34, 0.46), (0.14, 0.16)], color: Theme.amber, in: size)
            route([(0.34, 0.46), (0.55, 0.62), (0.70, 0.34)], color: Theme.teal, in: size)
            zone(x: 0.56, y: 0.22, w: targetSize, h: targetHeight, label: "CB target", color: Theme.teal, in: size)
        case "side_spin_ladder":
            route([(0.62, 0.68), (0.34, 0.46), (0.14, 0.16)], color: Theme.amber, in: size)
            route([(0.34, 0.46), (0.50, 0.72), (0.74, 0.38)], color: Theme.blue, in: size)
            zone(x: 0.58, y: 0.24, w: targetSize, h: targetHeight, label: "Spin finish", color: Theme.blue, in: size)
            spotTarget(x: 0.62, y: 0.68, label: "10 / 2", color: Theme.blue, in: size)
        case "gearing_outside_spin":
            route([(0.66, 0.66), (0.36, 0.42), (0.14, 0.16)], color: Theme.green, in: size)
            route([(0.36, 0.42), (0.54, 0.58), (0.74, 0.42)], color: Theme.teal, in: size)
            spotTarget(x: 0.66, y: 0.66, label: "Outside", color: Theme.green, in: size)
            zone(x: 0.58, y: 0.30, w: targetSize, h: targetHeight, label: "Natural lane", color: Theme.teal, in: size)
        case "clock_system_spin":
            route([(0.64, 0.68), (0.36, 0.43), (0.50, 0.74), (0.76, 0.36)], color: Theme.blue, in: size)
            spotTarget(x: 0.64, y: 0.68, label: "Clock", color: Theme.blue, in: size)
            zone(x: 0.58, y: 0.22, w: targetSize, h: targetHeight, label: "Called finish", color: Theme.blue, in: size)
        case "carom_touch":
            route([(0.28, 0.68), (0.42, 0.50)], color: Theme.amber, in: size)
            route([(0.42, 0.50), (0.66, 0.36)], color: Theme.teal, in: size)
            spotTarget(x: 0.66, y: 0.36, label: "Target ball", color: Theme.amber, in: size)
        case "safety_hide":
            zone(x: 0.58, y: 0.22, w: max(0.14, targetSize * 0.95), h: 0.34, label: "Hide lane", color: Theme.purple, in: size)
            tableLine(from: (0.52, 0.34), to: (0.78, 0.56), color: Theme.red, in: size)
            route([(0.30, 0.63), (0.47, 0.50), (0.70, 0.34)], color: Theme.purple, in: size)
        case "ghost_ball_aiming":
            route([(0.62, 0.68), (0.34, 0.42), (0.14, 0.16)], color: Theme.amber, in: size)
            ghostMarker(x: 0.45, y: 0.52, color: Theme.amber, in: size)
        case "up_down_speed_control":
            zone(x: 0.18, y: 0.10, w: 0.64, h: max(0.10, 0.22 - step * 0.025), label: "Far speed", color: Theme.teal, in: size)
            zone(x: 0.18, y: 0.68 + step * 0.012, w: 0.64, h: max(0.10, 0.22 - step * 0.025), label: "Return", color: Theme.blue, in: size)
            route([(0.50, 0.78), (0.50, 0.18), (0.50, 0.74)], color: Theme.teal, in: size)
        case "cross_line_speed":
            tableLine(from: (0.12, 0.50), to: (0.88, 0.50), color: Theme.amber, in: size)
            zone(x: 0.22, y: 0.24, w: 0.56, h: max(0.10, 0.24 - step * 0.03), label: "Stop lane", color: Theme.amber, in: size)
            route([(0.50, 0.78), (0.50, 0.38)], color: Theme.amber, in: size)
        case "one_rail_target_pool":
            route([(0.60, 0.70), (0.34, 0.46), (0.14, 0.16)], color: Theme.amber, in: size)
            route([(0.34, 0.46), (0.78, 0.76), (0.68, 0.36)], color: Theme.teal, in: size)
            zone(x: 0.58, y: 0.24, w: targetSize, h: targetHeight, label: "1 rail", color: Theme.teal, in: size)
        case "two_rail_target_pool":
            route([(0.62, 0.66), (0.34, 0.46), (0.14, 0.16)], color: Theme.amber, in: size)
            route([(0.34, 0.46), (0.78, 0.78), (0.86, 0.40), (0.62, 0.24)], color: Theme.blue, in: size)
            zone(x: 0.52, y: 0.16, w: targetSize, h: targetHeight, label: "2 rails", color: Theme.blue, in: size)
        case "three_rail_target_pool":
            route([(0.64, 0.62), (0.34, 0.46), (0.14, 0.16)], color: Theme.amber, in: size)
            route([(0.34, 0.46), (0.74, 0.78), (0.86, 0.24), (0.18, 0.18), (0.56, 0.38)], color: Theme.purple, in: size)
            zone(x: 0.46, y: 0.28, w: targetSize, h: targetHeight, label: "3 rails", color: Theme.purple, in: size)
        case "inside_outside_english":
            zone(x: 0.22, y: 0.24, w: 0.22, h: 0.54, label: "Inside", color: Theme.blue, in: size)
            zone(x: 0.56, y: 0.22, w: 0.22, h: 0.54, label: "Outside", color: Theme.green, in: size)
            route([(0.24, 0.72), (0.34, 0.32), (0.62, 0.58), (0.36, 0.72), (0.70, 0.38)], color: Theme.blue, in: size)
        case "side_pocket_cut_ladder":
            route([(0.24, 0.72), (0.46, 0.48), (0.50, 0.08)], color: Theme.amber, in: size)
            route([(0.46, 0.48), (0.62, 0.74), (0.76, 0.84)], color: Theme.blue, in: size)
            zone(x: 0.52, y: 0.64, w: targetSize, h: targetHeight, label: "Down-table", color: Theme.blue, in: size)
        case "brainwashing_no_rail":
            zone(x: 0.18, y: 0.24, w: 0.64, h: 0.52, label: "No rails", color: Theme.teal, in: size)
            route([(0.42, 0.68), (0.32, 0.35), (0.52, 0.38), (0.68, 0.45)], color: Theme.teal, in: size)
        case "one_rail_kick":
            route([(0.25, 0.73), (0.52, 0.84), (0.70, 0.36)], color: Theme.amber, in: size)
            tableLine(from: (0.46, 0.55), to: (0.74, 0.30), color: Theme.red, in: size)
            spotTarget(x: 0.70, y: 0.36, label: "Contact", color: Theme.amber, in: size)
        case "cross_side_bank":
            route([(0.54, 0.70), (0.38, 0.36), (0.50, 0.08)], color: Theme.amber, in: size)
            route([(0.38, 0.36), (0.50, 0.50)], color: Theme.blue, in: size)
            spotTarget(x: 0.50, y: 0.08, label: "Side pocket", color: Theme.amber, in: size)
        case "jump_escape_basic":
            zone(x: 0.41, y: 0.46, w: 0.10, h: 0.18, label: "Blocker", color: Theme.purple, in: size)
            zone(x: 0.57, y: 0.46, w: max(0.13, targetSize * 0.85), h: max(0.10, targetHeight * 0.75), label: "Land", color: Theme.green, in: size)
            route([(0.26, 0.73), (0.46, 0.42), (0.70, 0.36)], color: Theme.amber, in: size)
            spotTarget(x: 0.70, y: 0.36, label: "Contact", color: Theme.amber, in: size)
        case "break_control":
            zone(x: 0.34, y: 0.40, w: max(0.16, 0.32 - step * 0.025), h: max(0.13, 0.22 - step * 0.018), label: "CB finish", color: Theme.teal, in: size)
            route([(0.50, 0.78), (0.50, 0.20), (0.50, 0.52)], color: Theme.teal, in: size)
        case "center_ball_stroke":
            tableLine(from: (0.78, 0.50), to: (0.14, 0.50), color: Theme.teal, in: size)
            zone(x: 0.52, y: 0.42, w: targetSize, h: max(0.10, targetHeight * 0.70), label: "No side", color: Theme.teal, in: size)
            route([(progressiveCueX(level), 0.50), (0.32, 0.50), (0.14, 0.50)], color: Theme.teal, in: size)
        case "vision_center_alignment":
            tableLine(from: (0.82, 0.50), to: (0.14, 0.50), color: Theme.amber, in: size)
            tableLine(from: (0.82, 0.44), to: (0.14, 0.44), color: Theme.amber, in: size)
            tableLine(from: (0.82, 0.56), to: (0.14, 0.56), color: Theme.amber, in: size)
            route([(progressiveCueX(level), 0.50), (0.34, 0.50), (0.14, 0.50)], color: Theme.amber, in: size)
            spotTarget(x: progressiveCueX(level), y: 0.50, label: "Eyes", color: Theme.amber, in: size)
        case "t_drill":
            zone(x: 0.24, y: 0.28, w: 0.52, h: 0.17, label: "Top bar", color: Theme.teal, in: size)
            zone(x: 0.40, y: 0.42, w: 0.20, h: 0.34, label: "Stem", color: Theme.blue, in: size)
            route([(0.27, 0.76), (0.30, 0.36), (0.50, 0.36), (0.70, 0.36), (0.50, 0.52), (0.50, 0.68)], color: Theme.teal, in: size)
        case "down_rail_drill":
            zone(x: 0.08, y: 0.16, w: 0.18, h: 0.68, label: "Rail line", color: Theme.blue, in: size)
            tableLine(from: (0.28, 0.16), to: (0.28, 0.84), color: Theme.red, in: size)
            route([(0.38, 0.78), (0.19, 0.64), (0.19, 0.36), (0.10, 0.12)], color: Theme.blue, in: size)
        case "spot_rotation_drill":
            route([(0.64, 0.68), (0.50, 0.36), (0.14, 0.16)], color: Theme.amber, in: size)
            route([(0.50, 0.36), (0.42, 0.44), (0.58, 0.44), (0.36, 0.52)], color: Theme.purple, in: size)
            spotTarget(x: 0.50, y: 0.36, label: "Spot", color: Theme.amber, in: size)
            zone(x: 0.34, y: 0.32, w: 0.32, h: 0.34, label: "Rotation cluster", color: Theme.purple, in: size)
        default:
            switch template.pictureID {
            case "line_drill":
                tableLine(from: (0.50, 0.12), to: (0.50, 0.88), color: Theme.teal, in: size)
            case "straight_progressive":
                tableLine(from: (0.22, 0.50), to: (0.88, 0.50), color: Theme.teal, in: size)
            case "cut_progressive":
                route([(progressiveCueX(level), 0.72), (0.32, 0.36), (0.14, 0.16)], color: Theme.amber, in: size)
            case "rail_cut":
                route([(0.60, 0.72), (0.23, 0.22), (0.14, 0.16)], color: Theme.blue, in: size)
            case "spot_shot":
                tableLine(from: (0.50, 0.30), to: (0.50, 0.82), color: Theme.amber, in: size)
            case "kick_bank", "jump_escape_basic":
                zone(x: 0.60, y: 0.23, w: targetSize, h: targetHeight, label: "Contact", color: Theme.amber, in: size)
            case "break_control":
                zone(x: 0.35, y: 0.42, w: max(0.16, 0.32 - step * 0.025), h: max(0.13, 0.22 - step * 0.018), label: "CB finish", color: Theme.teal, in: size)
            case "circle_drill":
                Circle()
                    .fill(Theme.teal.opacity(0.10))
                    .overlay(Circle().stroke(Theme.teal.opacity(0.40), style: StrokeStyle(lineWidth: 1, dash: [6, 5])))
                    .frame(width: size.width * max(0.32, 0.54 - step * 0.045), height: size.width * max(0.32, 0.54 - step * 0.045))
                    .position(x: size.width * 0.50, y: size.height * 0.52)
            case "one_to_ten":
                zone(x: 0.10, y: 0.26, w: 0.22, h: 0.48, label: "A", color: Theme.blue, in: size)
                zone(x: 0.68, y: 0.26, w: 0.22, h: 0.48, label: "B", color: Theme.purple, in: size)
            case "t_drill":
                tableLine(from: (0.25, 0.36), to: (0.75, 0.36), color: Theme.teal, in: size)
                tableLine(from: (0.50, 0.36), to: (0.50, 0.74), color: Theme.teal, in: size)
            case "down_rail":
                zone(x: 0.08, y: 0.16, w: 0.18, h: 0.68, label: "Rail line", color: Theme.blue, in: size)
            case "spot_drill":
                route([(0.64, 0.68), (0.50, 0.36), (0.14, 0.16)], color: Theme.amber, in: size)
            default:
                EmptyView()
            }
        }
    }

    private func tableLine(from start: (Double, Double), to end: (Double, Double), color: Color, in size: CGSize) -> some View {
        Path { path in
            path.move(to: CGPoint(x: size.width * start.0, y: size.height * start.1))
            path.addLine(to: CGPoint(x: size.width * end.0, y: size.height * end.1))
        }
        .stroke(color.opacity(0.42), style: StrokeStyle(lineWidth: max(1.4, min(size.width, size.height) * 0.012), lineCap: .round, dash: [5, 5]))
    }

    private func route(_ points: [(Double, Double)], color: Color, in size: CGSize) -> some View {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: CGPoint(x: size.width * first.0, y: size.height * first.1))
            for point in points.dropFirst() {
                path.addLine(to: CGPoint(x: size.width * point.0, y: size.height * point.1))
            }
        }
        .stroke(color.opacity(0.58), style: StrokeStyle(lineWidth: max(1.4, min(size.width, size.height) * 0.014), lineCap: .round, lineJoin: .round, dash: [7, 5]))
    }

    private func ghostMarker(x: Double, y: Double, color: Color, in size: CGSize) -> some View {
        Circle()
            .fill(Color.white.opacity(0.10))
            .overlay(Circle().stroke(color.opacity(0.55), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3])))
            .frame(width: max(16, min(size.width, size.height) * 0.10), height: max(16, min(size.width, size.height) * 0.10))
            .position(x: size.width * x, y: size.height * y)
    }

    private func spotTarget(x: Double, y: Double, label: String, color: Color, in size: CGSize) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.10))
                .overlay(Circle().stroke(color.opacity(0.55), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3])))
            Text(LocalizedStringKey(label))
                .font(.system(size: max(7, min(size.width, size.height) * 0.038), weight: .black, design: .rounded))
                .foregroundColor(color.opacity(0.88))
                .offset(y: -max(17, min(size.width, size.height) * 0.11))
        }
        .frame(width: max(22, min(size.width, size.height) * 0.13), height: max(22, min(size.width, size.height) * 0.13))
        .position(x: size.width * x, y: size.height * y)
    }

    private func zone(x: Double, y: Double, w: Double, h: Double, label: String, color: Color, in size: CGSize) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(color.opacity(0.12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.42), style: StrokeStyle(lineWidth: 1, dash: [6, 5])))
            .overlay(alignment: .topLeading) {
                Text(LocalizedStringKey(label))
                    .font(.system(size: max(7, min(size.width, size.height) * 0.04), weight: .bold))
                    .foregroundColor(color.opacity(0.8))
                    .padding(6)
            }
            .frame(width: size.width * w, height: size.height * h)
            .position(x: size.width * (x + w / 2), y: size.height * (y + h / 2))
    }

    private func balls(for template: DrillTemplate, ballCount: Int, level: DrillDifficultyLevel) -> [PictureBall] {
        let count = max(0, min(ballCount, 15))

        func cuePlus(_ cuePoint: (Double, Double), _ coords: [(Double, Double)], limit: Int? = nil) -> [PictureBall] {
            let visible = Array(coords.prefix(limit ?? coords.count))
            return [PictureBall(id: "cue", number: 0, x: cuePoint.0, y: cuePoint.1)] + visible.enumerated().map { idx, coord in
                PictureBall(id: "ball-\(idx + 1)", number: idx + 1, x: coord.0, y: coord.1)
            }
        }

        func cuePlusNumbered(_ cuePoint: (Double, Double), _ coords: [(Int, Double, Double)], limit: Int? = nil) -> [PictureBall] {
            let visible = Array(coords.prefix(limit ?? coords.count))
            return [PictureBall(id: "cue", number: 0, x: cuePoint.0, y: cuePoint.1)] + visible.map { number, x, y in
                PictureBall(id: "ball-\(number)", number: number, x: x, y: y)
            }
        }

        let openCoords = [(0.22,0.26),(0.40,0.66),(0.58,0.31),(0.76,0.70),(0.70,0.43),(0.48,0.50),(0.33,0.39),(0.62,0.60),(0.26,0.75),(0.78,0.25),(0.18,0.52),(0.50,0.78),(0.83,0.55),(0.41,0.23),(0.68,0.82)]
        let rackCoords = [(0.50,0.20),(0.46,0.27),(0.54,0.27),(0.42,0.34),(0.50,0.34),(0.58,0.34),(0.38,0.41),(0.46,0.41),(0.54,0.41),(0.62,0.41),(0.34,0.48),(0.42,0.48),(0.50,0.48),(0.58,0.48),(0.66,0.48)]
        let ghostCoords = [(1,0.34,0.40),(2,0.56,0.58),(3,0.72,0.34),(4,0.42,0.66),(5,0.66,0.70),(6,0.48,0.30),(7,0.78,0.54)]
        let rotationCoords = [(1,0.34,0.58),(2,0.48,0.35),(3,0.62,0.62),(4,0.76,0.38),(5,0.42,0.74),(6,0.28,0.34),(7,0.70,0.74),(8,0.54,0.48),(9,0.82,0.58),(10,0.38,0.24),(11,0.22,0.66),(12,0.58,0.24),(13,0.72,0.52),(14,0.46,0.64),(15,0.66,0.30)]
        let eightBallGroupCoords = [(1,0.36,0.38),(2,0.50,0.62),(3,0.66,0.42),(4,0.42,0.76),(5,0.72,0.64),(6,0.52,0.34),(7,0.30,0.58)]
        let presetPatternCoords = [(1,0.42,0.42),(2,0.56,0.60),(3,0.72,0.42),(4,0.34,0.62),(5,0.64,0.30),(6,0.48,0.72),(7,0.78,0.58)]
        let breakLikeCoords = [(1,0.44,0.34),(2,0.62,0.48),(3,0.76,0.28),(4,0.36,0.56),(5,0.70,0.68),(6,0.54,0.22),(7,0.82,0.52),(8,0.48,0.70),(9,0.66,0.36)]
        let scoringCoords = [(1,0.24,0.26),(2,0.42,0.36),(3,0.60,0.24),(4,0.78,0.44),(5,0.32,0.58),(6,0.54,0.68),(7,0.72,0.72),(8,0.48,0.48),(9,0.22,0.74),(10,0.66,0.56),(11,0.38,0.24),(12,0.82,0.62),(13,0.56,0.36),(14,0.30,0.42),(15,0.70,0.30)]
        let noRailCoords = [(0.32,0.35),(0.52,0.38),(0.68,0.45),(0.38,0.55),(0.58,0.62),(0.48,0.47),(0.66,0.34)]

        switch template.id {
        case "l_drill":
            return cuePlus((0.20, 0.70), [(0.26,0.70),(0.26,0.62),(0.26,0.54),(0.26,0.46),(0.26,0.38),(0.26,0.30),(0.26,0.22),(0.36,0.70),(0.46,0.70),(0.56,0.70),(0.66,0.70),(0.76,0.70),(0.84,0.70),(0.84,0.62),(0.84,0.54)], limit: count)
        case "one_side_pattern":
            return cuePlus((0.34, 0.78), [(0.44,0.22),(0.48,0.30),(0.51,0.38),(0.54,0.46),(0.57,0.54),(0.60,0.62),(0.55,0.70),(0.49,0.76),(0.64,0.34),(0.67,0.48),(0.43,0.62),(0.39,0.72)], limit: count)
        case "centerline_control":
            return cuePlus((0.50, 0.52), [(0.50,0.27),(0.63,0.31),(0.72,0.43),(0.72,0.59),(0.63,0.71),(0.50,0.75),(0.37,0.71),(0.28,0.59),(0.28,0.43),(0.37,0.31),(0.58,0.40),(0.42,0.64)], limit: count)
        case "rail_avoidance":
            return cuePlus((0.18, 0.80), [(0.24,0.33),(0.76,0.33),(0.24,0.43),(0.76,0.43),(0.24,0.53),(0.76,0.53),(0.24,0.63),(0.76,0.63),(0.24,0.73),(0.76,0.73)], limit: count)
        case "open_table_runout":
            return cuePlus((0.25, 0.72), [(0.38,0.34),(0.56,0.58),(0.72,0.36),(0.44,0.68),(0.68,0.68),(0.52,0.28),(0.30,0.54)], limit: count)
        case "three_ball_ghost":
            return cuePlusNumbered((0.26, 0.72), ghostCoords, limit: count)
        case "nine_ball_ghost":
            return cuePlusNumbered((0.24, 0.72), rotationCoords, limit: min(count, 9))
        case "fargo_rotation", "fifteen_ball_rotation":
            return cuePlusNumbered((0.24, 0.72), rotationCoords, limit: count)
        case "eight_ball_pattern":
            let groupCount = max(0, min(count - 1, eightBallGroupCoords.count))
            let groupBalls = Array(eightBallGroupCoords.prefix(groupCount)).enumerated().map { idx, coord in
                PictureBall(id: "ball-\(idx + 1)", number: idx + 1, x: coord.1, y: coord.2)
            }
            return [PictureBall(id: "cue", number: 0, x: 0.25, y: 0.72)] + groupBalls + [PictureBall(id: "ball-8", number: 8, x: 0.72, y: 0.30)]
        case "placement_pool_challenge":
            return cuePlusNumbered((0.28, 0.70), presetPatternCoords, limit: count)
        case "rds_break_run":
            return cuePlusNumbered((0.30, 0.74), breakLikeCoords, limit: count)
        case "equal_offense":
            return cuePlusNumbered((0.20, 0.76), scoringCoords, limit: count)
        case "hopkins_q_skills":
            return cuePlusNumbered((0.20, 0.76), [(1,0.24,0.26),(2,0.42,0.36),(3,0.60,0.24),(4,0.78,0.44),(5,0.32,0.58),(6,0.54,0.68),(7,0.72,0.72),(8,0.48,0.48),(9,0.22,0.74),(10,0.66,0.56),(11,0.38,0.24),(12,0.82,0.62),(13,0.56,0.36),(14,0.30,0.42),(15,0.70,0.30)], limit: count)
        case "no_rail_pattern", "brainwashing_no_rail":
            return cuePlus((0.42, 0.68), noRailCoords, limit: count)
        case "wagon_wheel":
            return cuePlus((0.34, 0.50), [(0.52, 0.55)])
        case "cut_shot_progressive":
            return cuePlus((progressiveCueX(level), 0.70), [(0.36, 0.42)])
        case "rail_cut_progressive":
            return cuePlus((0.62, 0.72), [(0.23, 0.26)])
        case "spot_shot_challenge":
            return cuePlus((0.42, 0.78), [(0.50, 0.30)])
        case "long_straight_in":
            return cuePlus((0.74, 0.50), [(0.34, 0.50)])
        case "thin_cut_ladder":
            return cuePlus((0.72, 0.72), [(0.38, 0.46)])
        case "back_cut_ladder":
            return cuePlus((0.28, 0.72), [(0.58, 0.42)])
        case "target_pool":
            return cuePlus((0.62, 0.68), [(0.34, 0.46)])
        case "side_spin_ladder":
            return cuePlus((0.62, 0.68), [(0.34, 0.46)])
        case "center_ball_stroke":
            return cuePlus((progressiveCueX(level), 0.50), [(0.32, 0.50)])
        case "vision_center_alignment":
            return cuePlus((progressiveCueX(level), 0.50), [(0.34, 0.50)])
        case "follow_progressive", "draw_progressive", "stop_shot_ladder":
            return cuePlus((progressiveCueX(level), 0.50), [(0.32, 0.50)])
        case "stun_tangent_line":
            return cuePlus((0.64 + difficultyStep(level) * 0.025, 0.66), [(0.38, 0.44)])
        case "gearing_outside_spin":
            return cuePlus((0.66, 0.66), [(0.36, 0.42)])
        case "clock_system_spin":
            return cuePlus((0.64, 0.68), [(0.36, 0.43)])
        case "ghost_ball_aiming":
            return cuePlus((progressiveCueX(level), 0.70), [(0.34, 0.42)])
        case "one_rail_target_pool":
            return cuePlus((0.60, 0.70), [(0.34, 0.46)])
        case "two_rail_target_pool":
            return cuePlus((0.62, 0.66), [(0.34, 0.46)])
        case "three_rail_target_pool":
            return cuePlus((0.64, 0.62), [(0.34, 0.46)])
        case "safety_hide":
            return cuePlusNumbered((0.30, 0.63), [(1, 0.47, 0.50), (8, 0.58, 0.38), (9, 0.70, 0.34)])
        case "carom_touch":
            return cuePlusNumbered((0.28, 0.68), [(1, 0.42, 0.50), (2, 0.66, 0.36)])
        case "one_rail_kick":
            return cuePlusNumbered((0.25, 0.73), [(1, 0.70, 0.36), (8, 0.47, 0.55)])
        case "cross_side_bank":
            return cuePlus((0.54, 0.70), [(0.38, 0.36), (0.50, 0.50)], limit: 2)
        case "jump_escape_basic":
            return cuePlusNumbered((0.26, 0.73), [(1, 0.70, 0.36), (8, 0.46, 0.55)])
        case "break_control":
            return cuePlus((0.50, 0.78), rackCoords, limit: rackCoords.count)
        case "t_drill":
            return cuePlus((0.27, 0.76), [(0.30,0.36),(0.40,0.36),(0.50,0.36),(0.60,0.36),(0.70,0.36),(0.50,0.44),(0.50,0.52),(0.50,0.60),(0.50,0.68),(0.40,0.44),(0.60,0.44),(0.40,0.52),(0.60,0.52),(0.40,0.60),(0.60,0.60)], limit: count)
        case "down_rail_drill":
            return cuePlus((0.38, 0.78), [(0.19,0.22),(0.19,0.29),(0.19,0.36),(0.19,0.43),(0.19,0.50),(0.19,0.57),(0.19,0.64),(0.19,0.71),(0.19,0.78),(0.27,0.25),(0.27,0.34),(0.27,0.43),(0.27,0.52),(0.27,0.61),(0.27,0.70)], limit: count)
        case "spot_rotation_drill":
            return cuePlus((0.64, 0.68), [(0.50,0.36),(0.42,0.44),(0.58,0.44),(0.36,0.52),(0.64,0.52),(0.44,0.60),(0.56,0.60),(0.50,0.28),(0.34,0.36),(0.66,0.36)], limit: count)
        case "inside_outside_english":
            return cuePlus((0.24, 0.72), [(0.34,0.32),(0.66,0.68),(0.38,0.42),(0.62,0.58),(0.42,0.52),(0.58,0.48),(0.30,0.62),(0.70,0.38),(0.36,0.72),(0.64,0.28)], limit: count)
        case "side_pocket_cut_ladder":
            return cuePlus((0.24, 0.72), [(0.46,0.48)])
        case "up_down_speed_control", "cross_line_speed":
            return [PictureBall(id: "cue", number: 0, x: 0.50, y: 0.78)]
        default:
            switch template.pictureID {
            case "line_drill":
                return cuePlus((0.35, 0.78), [(0.50,0.18),(0.50,0.25),(0.50,0.32),(0.50,0.39),(0.50,0.46),(0.50,0.53),(0.50,0.60),(0.50,0.67),(0.50,0.74),(0.42,0.50),(0.58,0.50),(0.42,0.62)], limit: count)
            case "rail_cut":
                return cuePlus((0.60, 0.72), [(0.23,0.22)])
            case "spot_shot":
                return cuePlus((0.50, 0.78), [(0.50,0.30)])
            case "circle_drill":
                return cuePlus((0.50, 0.52), [(0.50,0.27),(0.63,0.31),(0.72,0.43),(0.72,0.59),(0.63,0.71),(0.50,0.75),(0.37,0.71),(0.28,0.59),(0.28,0.43),(0.37,0.31),(0.58,0.40),(0.42,0.64)], limit: count)
            case "one_to_ten":
                return cuePlus((0.18, 0.80), [(0.24,0.33),(0.76,0.33),(0.24,0.43),(0.76,0.43),(0.24,0.53),(0.76,0.53),(0.24,0.63),(0.76,0.63),(0.24,0.73),(0.76,0.73)], limit: count)
            default:
                return cuePlus((0.28, 0.52), openCoords, limit: count)
            }
        }
    }

    private func progressiveCueX(_ level: DrillDifficultyLevel) -> Double {
        0.56 + difficultyStep(level) * 0.045
    }

    private func difficultyStep(_ level: DrillDifficultyLevel) -> Double {
        switch level {
        case .beginner: return 0
        case .easy: return 1
        case .standard: return 2
        case .hard: return 3
        case .expert: return 4
        }
    }

    private func ballView(_ ball: PictureBall, in size: CGSize) -> some View {
        let diameter = max(6.5, min(14, min(size.width, size.height) * 0.056))
        return ZStack {
            if ball.number == 0 {
                Circle().fill(Color.white)
            } else if ball.number >= 9 {
                Circle().fill(Color.white)
                Rectangle()
                    .fill(poolBallColor(ball.number))
                    .frame(width: diameter, height: diameter * 0.42)
                    .clipShape(Circle())
                Circle().stroke(poolBallColor(ball.number), lineWidth: max(1, diameter * 0.08))
            } else {
                Circle().fill(poolBallColor(ball.number))
                if ball.number != 8 {
                    Circle().fill(Color.white.opacity(0.94)).frame(width: diameter * 0.54, height: diameter * 0.54)
                }
            }
            Text(ball.number == 0 ? "C" : "\(ball.number)")
                .font(.system(size: max(4.8, diameter * (ball.number >= 10 ? 0.34 : 0.43)), weight: .black, design: .rounded))
                .foregroundColor(ball.number == 8 ? .white : .black.opacity(0.84))
        }
        .frame(width: diameter, height: diameter)
        .shadow(color: .black.opacity(0.32), radius: 3, x: 0, y: 2)
        .position(x: size.width * ball.x, y: size.height * ball.y)
    }
}

private struct PictureBall: Identifiable {
    let id: String
    let number: Int
    let x: Double
    let y: Double
}
private func poolBallColor(_ number: Int) -> Color {
    switch number {
    case 1, 9: return Color(red: 0.96, green: 0.78, blue: 0.18)
    case 2, 10: return Color(red: 0.16, green: 0.45, blue: 0.88)
    case 3, 11: return Color(red: 0.88, green: 0.18, blue: 0.24)
    case 4, 12: return Color(red: 0.45, green: 0.24, blue: 0.78)
    case 5, 13: return Color(red: 0.95, green: 0.48, blue: 0.12)
    case 6, 14: return Color(red: 0.18, green: 0.58, blue: 0.25)
    case 7, 15: return Color(red: 0.50, green: 0.10, blue: 0.12)
    case 8: return Color.black
    default: return Color.white
    }
}
