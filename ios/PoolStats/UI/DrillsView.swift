import SwiftUI

struct DrillsView: View {
    @EnvironmentObject private var drillStore: DrillStore
    private let tabBarClearance: CGFloat = 74

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header

                if let activeRun = drillStore.activeRun {
                    ActiveDrillCard(run: activeRun)
                }

                SectionCard(title: "Generate a drill") {
                    VStack(spacing: 10) {
                        ForEach(DrillLibrary.templates) { template in
                            DrillTemplateRow(template: template)
                        }
                    }
                }

                if !drillStore.runs.isEmpty {
                    recentRuns
                }
            }
            .padding(.horizontal, Layout.pagePadding)
            .padding(.top, 4)
            .padding(.bottom, 12 + tabBarClearance)
        }
        .background(Theme.bg)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Drills")
                .font(.title.bold())
                .foregroundColor(Theme.text)
            Text("Generate a table layout, run the drill, and track attempts without mixing it into match stats.")
                .font(.caption)
                .foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recentRuns: some View {
        SectionCard(title: "Recent drill runs") {
            VStack(spacing: 8) {
                ForEach(drillStore.runs.prefix(8)) { run in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(run.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Theme.text)
                                .lineLimit(1)
                            Text(AppFormatters.shortDateTime(run.startedAt))
                                .font(.caption2)
                                .foregroundColor(Theme.muted)
                        }
                        Spacer(minLength: 8)
                        metricPill(label: "Attempts", value: "\(run.attempts)", color: Theme.text2)
                        metricPill(label: "Success", value: run.successRate.map { "\($0)%" } ?? "—", color: Theme.green)
                    }
                    .padding(10)
                    .background(Theme.panel2.opacity(0.75))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
                }
            }
        }
    }

    private func metricPill(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(label.uppercased())
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(Theme.muted)
            Text(value)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundColor(color)
        }
        .frame(width: 58)
    }
}

private struct DrillTemplateRow: View {
    @EnvironmentObject private var drillStore: DrillStore
    let template: DrillTemplate

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(accent.opacity(0.16))
                    .frame(width: 44, height: 44)
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(template.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.text)
                    Text(template.difficulty)
                        .font(.caption2.weight(.bold))
                        .foregroundColor(accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(accent.opacity(0.12))
                        .cornerRadius(6)
                }
                Text(template.subtitle)
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Button {
                drillStore.startRun(template: template)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                Text("Start")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.bg)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(accent)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Theme.panel2)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.5))
    }

    private var accent: Color {
        drillColor(template.accentName)
    }
}

private struct ActiveDrillCard: View {
    @EnvironmentObject private var drillStore: DrillStore
    @State private var notesDraft: String = ""
    let run: DrillRun

    var body: some View {
        SectionCard(title: "Active drill") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(run.title)
                            .font(.headline)
                            .foregroundColor(Theme.text)
                        Text("Seed \(run.generated.seed)")
                            .font(.caption2)
                            .foregroundColor(Theme.muted)
                    }
                    Spacer()
                    Text(run.successRate.map { "\($0)% success" } ?? "No attempts")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.green)
                }

                DrillTableDiagram(generated: run.generated)
                    .frame(height: 210)

                counterRow

                actionRow

                instructions

                TextField("Notes for this run", text: $notesDraft, axis: .vertical)
                    .lineLimit(2...4)
                    .font(.caption)
                    .foregroundColor(Theme.text)
                    .padding(10)
                    .background(Theme.panel2)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
                    .onAppear {
                        notesDraft = run.notes
                    }
                    .onChange(of: run.id) { _ in
                        notesDraft = run.notes
                    }
                    .onChange(of: notesDraft) { newValue in
                        drillStore.updateNotes(newValue)
                    }
            }
        }
    }

    private var counterRow: some View {
        HStack(spacing: 8) {
            counterTile("Attempts", "\(run.attempts)", Theme.text2)
            counterTile("Success", "\(run.successes)", Theme.green)
            counterTile("Miss", "\(run.misses)", Theme.red)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            drillButton("Attempt", color: Theme.text2) {
                drillStore.recordAttempt()
            }
            drillButton("Success", color: Theme.green) {
                drillStore.recordSuccess()
            }
            drillButton("Miss", color: Theme.red) {
                drillStore.recordMiss()
            }
            drillButton("Reset layout", color: Theme.amber) {
                drillStore.regenerateActiveLayout()
            }
            drillButton("End", color: Theme.purple) {
                drillStore.finishActiveRun()
            }
        }
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(run.generated.instructions, id: \.self) { item in
                labelLine(icon: "list.bullet", text: item, color: Theme.text2)
            }
            ForEach(run.generated.constraints, id: \.self) { item in
                labelLine(icon: "exclamationmark.circle", text: item, color: Theme.amber)
            }
        }
    }

    private func counterTile(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Theme.muted)
            Text(value)
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Theme.panel2)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
    }

    private func drillButton(_ label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            action()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(color.opacity(0.12))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.28), lineWidth: 0.6))
        }
        .buttonStyle(.plain)
    }

    private func labelLine(icon: String, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
                .foregroundColor(color)
                .frame(width: 14, alignment: .center)
            Text(text)
                .font(.caption)
                .foregroundColor(Theme.text2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct DrillTableDiagram: View {
    let generated: GeneratedDrill

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.03, green: 0.27, blue: 0.22), Color(red: 0.01, green: 0.17, blue: 0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 2)
                    .padding(4)

                ForEach(Array(pocketPositions(in: size).enumerated()), id: \.offset) { _, point in
                    Circle()
                        .fill(Color.black.opacity(0.82))
                        .frame(width: 18, height: 18)
                        .position(point)
                }

                ForEach(generated.zones) { zone in
                    zoneView(zone, in: size)
                }

                ForEach(generated.balls) { ball in
                    ballView(ball, in: size)
                }
            }
        }
    }

    private func pocketPositions(in size: CGSize) -> [CGPoint] {
        [
            CGPoint(x: 16, y: 16),
            CGPoint(x: size.width / 2, y: 10),
            CGPoint(x: size.width - 16, y: 16),
            CGPoint(x: 16, y: size.height - 16),
            CGPoint(x: size.width / 2, y: size.height - 10),
            CGPoint(x: size.width - 16, y: size.height - 16)
        ]
    }

    private func zoneView(_ zone: DrillZone, in size: CGSize) -> some View {
        let color = drillColor(zone.colorName)
        return RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(color.opacity(zone.isForbidden ? 0.14 : 0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(color.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: zone.isForbidden ? [6, 5] : [3, 4]))
            )
            .frame(width: size.width * zone.width, height: size.height * zone.height)
            .overlay(alignment: .topLeading) {
                Text(zone.label)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(color.opacity(0.75))
                    .padding(5)
            }
            .position(x: size.width * (zone.x + zone.width / 2), y: size.height * (zone.y + zone.height / 2))
    }

    private func ballView(_ ball: DrillBall, in size: CGSize) -> some View {
        let point = CGPoint(x: size.width * ball.position.x, y: size.height * ball.position.y)
        let fill = drillColor(ball.colorName)
        return ZStack {
            Circle()
                .fill(fill)
            Circle()
                .fill(Color.white.opacity(ball.colorName == "white" ? 0 : 0.9))
                .frame(width: 16, height: 16)
            Text(ball.label)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundColor(ball.colorName == "white" ? .black.opacity(0.78) : .black)
        }
        .frame(width: 28, height: 28)
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        .position(point)
    }
}

private func drillColor(_ name: String) -> Color {
    switch name {
    case "green": return Theme.green
    case "blue": return Theme.blue
    case "red": return Theme.red
    case "purple": return Theme.purple
    case "amber", "orange", "yellow": return Theme.amber
    case "teal": return Theme.teal
    case "white": return Color.white
    default: return Theme.text2
    }
}
