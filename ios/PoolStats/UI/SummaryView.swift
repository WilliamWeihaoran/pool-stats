import SwiftUI
import UIKit

struct SummaryView: View {
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var opponentStore: OpponentStore
    @Environment(\.horizontalSizeClass) private var hSizeClass

    let session: Session
    @State private var labelText: String = ""
    @State private var opponentText: String = ""
    @State private var performanceRating: Int? = nil
    @State private var performanceValue: Int = 5

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                AppBackButton(label: "Back")
                    .frame(maxWidth: .infinity, alignment: .leading)
                header
                timeSection
                performanceSection
                if session.isDrillPractice {
                    drillSummaryCards
                    drillAttemptLogSection
                } else {
                    summaryCards
                    errorsSection
                    breaksSection
                    rackLogSection
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(Theme.bg)
        .navigationTitle("Summary")
        .toolbar(.hidden, for: .navigationBar)
        .appBackSwipeEnabled()
        .onAppear {
            labelText = session.label
            opponentText = session.opponent
            performanceRating = session.performanceRating
            performanceValue = session.performanceRating ?? 5
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(metaText())
                .font(.caption)
                .foregroundColor(Theme.muted)
            TextField("Add a session label…", text: $labelText, onCommit: saveLabel)
                .textFieldStyle(.roundedBorder)
            if !session.isPractice {
                opponentEditor
            }
        }
    }

    private var opponentEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Opponent")
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                Spacer(minLength: 0)
                Text(opponentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Optional" : opponentText.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.caption2.weight(.medium))
                    .foregroundColor(Theme.text2)
            }

            TextField("Opponent name", text: $opponentText, onCommit: saveOpponent)
                .textFieldStyle(.roundedBorder)

            if !opponentSuggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(opponentSuggestions.prefix(8), id: \.self) { name in
                            Button {
                                opponentText = name
                                saveOpponent()
                            } label: {
                                Text(name)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(Theme.text)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Theme.panel2)
                                    .cornerRadius(999)
                                    .overlay(Capsule().stroke(Theme.border, lineWidth: 0.6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var summaryCards: some View {
        let rs = session.racks
        let n = Double(max(rs.count, 1))
        let runouts = rs.filter { $0.outcome == "runout" }.count
        let errTotal = rs.reduce(0) { $0 + $1.unforcedErrorCount }

        let top: [(String, String)]
        if session.isPractice {
            top = [
                ("Racks", "\(rs.count)"),
                ("Runouts", "\(runouts)"),
                ("Err/rack", String(format: "%.1f", Double(errTotal) / n)),
                ("Rating", session.performanceRating.map { "\($0)/10" } ?? "—")
            ]
        } else {
            top = [
                ("Racks", "\(rs.count)"),
                ("Won", "\(session.wins)"),
                ("Lost", "\(session.losses)"),
                ("Win%", rs.isEmpty ? "—" : "\(Int(round(Double(session.wins) / Double(rs.count) * 100)))%")
            ]
        }

        return SectionCard(title: "Summary") {
            LazyVGrid(columns: Layout.fourColumn(), spacing: 8) {
                ForEach(top, id: \.0) { item in
                    MiniStatCard(label: item.0, value: item.1)
                }
            }
        }
    }

    private var timeSection: some View {
        let duration = session.durationSeconds.map(TimeInterval.init)
        let rawValue = duration.map(AppFormatters.elapsed) ?? "—"
        let adjustedValue = duration.map { AppFormatters.elapsed(session.bufferedSessionSeconds(totalSeconds: $0)) } ?? "—"
        let pacePct = duration.map { session.bufferedPacePercent(totalSeconds: $0) } ?? 0
        let bufferPct = session.bufferedPaceBufferPercent()
        let rackCount = max(session.racks.count, 1)
        let avgRawRack = duration.map { AppFormatters.elapsed($0 / Double(rackCount)) } ?? "—"
        let avgAdjRack = duration.map { AppFormatters.elapsed(session.bufferedAverageRackSeconds(totalSeconds: $0)) } ?? "—"

        return SectionCard(title: "Time") {
            VStack(alignment: .leading, spacing: 10) {
                LazyVGrid(columns: Layout.fourColumn(), spacing: 8) {
                    MiniStatCard(label: "Raw", value: rawValue)
                    MiniStatCard(label: "Adjusted", value: adjustedValue)
                    MiniStatCard(label: "Avg raw", value: avgRawRack)
                    MiniStatCard(label: "Avg adj", value: avgAdjRack)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Avg pace")
                            .font(.caption2)
                            .foregroundColor(Theme.muted)
                        Spacer(minLength: 0)
                        Text("subtracts 45s setup buffer per rack")
                            .font(.caption2)
                            .foregroundColor(Theme.amber)
                    }
                    BufferedPaceBar(value: pacePct, bufferColor: Theme.amber, activeColor: Theme.green, bufferPercent: bufferPct, height: 5)
                }
            }
        }
    }

    private var performanceSection: some View {
        SectionCard(title: "Performance") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("Rate your session")
                        .font(.caption)
                        .foregroundColor(Theme.text2)
                    Spacer()
                    Text(performanceRating.map { "\($0)/10" } ?? "Drag to rate")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(performanceRating == nil ? Theme.muted : performanceSliderColor)
                }

                VStack(spacing: 8) {
                    DiscreteRatingSlider(value: Binding(
                        get: { performanceValue },
                        set: { newValue in
                            performanceValue = newValue
                            performanceRating = newValue
                            savePerformanceRating(newValue)
                        }
                    ), range: 1...10, activeColor: performanceSliderColor)
                    HStack {
                        Text("1")
                            .font(.caption2)
                            .foregroundColor(ratingColor(for: 1, lowerBound: 1, upperBound: 10))
                        Spacer()
                        Text("10")
                            .font(.caption2)
                            .foregroundColor(ratingColor(for: 10, lowerBound: 1, upperBound: 10))
                    }
                }
            }
        }
    }

    private var performanceSliderColor: Color {
        guard performanceRating != nil else { return Theme.purple }
        return ratingColor(for: performanceValue, lowerBound: 1, upperBound: 10)
    }

    private func ratingColor(for value: Int, lowerBound: Int, upperBound: Int) -> Color {
        let clamped = Double(Swift.max(Swift.min(value, upperBound), lowerBound))
        let mid = Double(lowerBound + upperBound) / 2.0

        if clamped <= mid {
            let t = (clamped - Double(lowerBound)) / Swift.max(mid - Double(lowerBound), 1)
            return interpolateColor(from: .red, to: .orange, progress: t)
        } else {
            let t = (clamped - mid) / Swift.max(Double(upperBound) - mid, 1)
            return interpolateColor(from: .orange, to: .green, progress: t)
        }
    }

    private func interpolateColor(from start: UIColor, to end: UIColor, progress: Double) -> Color {
        let p = min(max(progress, 0), 1)
        let s = start.rgbaComponents
        let e = end.rgbaComponents
        let r = s.r + (e.r - s.r) * p
        let g = s.g + (e.g - s.g) * p
        let b = s.b + (e.b - s.b) * p
        let a = s.a + (e.a - s.a) * p
        return Color(red: r, green: g, blue: b, opacity: a)
    }

    private var drillSummaryCards: some View {
        let attempts = session.drillAttempts
        let successes = session.drillSuccesses
        let misses = session.drillMisses
        let rate = session.drillSuccessRate.map { "\($0)%" } ?? "--"
        let template = DrillLibrary.template(id: session.drillID)
        let totalCompleted = session.racks.reduce(0) { $0 + ($1.drillBallsMade ?? 0) }
        let avgCompleted = attempts == 0 ? "--" : String(format: "%.1f", Double(totalCompleted) / Double(attempts))
        let averageLabel = template?.progressTitle() == "Potted" ? "Avg potted" : "Avg completed"
        let progress = session.drillTargetProgress

        return SectionCard(title: "Practice") {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.drillTitle ?? session.displayLabel)
                        .font(.headline.weight(.bold))
                        .foregroundColor(Theme.text)
                    HStack(spacing: 8) {
                        badge(text: session.drillDifficultyLabel, color: Theme.purple)
                        if let count = session.drillBallCount { badge(text: template?.countText(count) ?? "\(count) reps", color: Theme.amber) }
                        if let target = session.drillTargetLabel { badge(text: target, color: Theme.green) }
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(successes)")
                        .font(.system(size: 44, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundColor(Theme.green)
                    Text(":")
                        .font(.system(size: 36, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundColor(Theme.text2)
                    Text("\(misses)")
                        .font(.system(size: 44, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundColor(Theme.red)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(rate)
                            .font(.title3.bold().monospacedDigit())
                            .foregroundColor(Theme.text)
                        Text("success rate")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(Theme.muted)
                    }
                }

                if let progress {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("Target progress")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Theme.text2)
                            Spacer()
                            Text("\(progress.current)/\(progress.target)")
                                .font(.caption.weight(.bold).monospacedDigit())
                                .foregroundColor(Theme.green)
                        }
                        ProgressView(value: Double(progress.current), total: Double(max(progress.target, 1)))
                            .tint(Theme.green)
                    }
                }

                LazyVGrid(columns: Layout.fourColumn(), spacing: 8) {
                    MiniStatCard(label: "Attempts", value: "\(attempts)")
                    MiniStatCard(label: "Success", value: "\(successes)")
                    MiniStatCard(label: "Miss", value: "\(misses)")
                    MiniStatCard(label: averageLabel, value: avgCompleted)
                }
            }
        }
    }

    private var drillAttemptLogSection: some View {
        let mistakeCounts = Dictionary(grouping: session.racks.flatMap { $0.drillTags ?? [] }, by: { $0 })
            .mapValues { $0.count }
        return SectionCard(title: "Attempt log") {
            VStack(alignment: .leading, spacing: 10) {
                if !mistakeCounts.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mistakes")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Theme.muted)
                        HStack(spacing: 6) {
                            ForEach(mistakeCounts.keys.sorted(), id: \.self) { tag in
                                badge(text: "\(tag) \(mistakeCounts[tag] ?? 0)", color: Theme.teal)
                            }
                        }
                    }
                }
                VStack(spacing: 8) {
                    ForEach(session.racks) { rack in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text("\(rack.index)")
                                    .font(.caption)
                                    .foregroundColor(Theme.muted)
                                    .frame(width: 20, alignment: .leading)
                                Text(rack.drillOutcomeLabel)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(rack.drillOutcome == "success" ? Theme.green : Theme.red)
                                if let made = rack.drillBallsMade, let target = rack.drillTargetBallCount {
                                    Text("\(made)/\(target) potted")
                                        .font(.caption.weight(.bold).monospacedDigit())
                                        .foregroundColor(Theme.text2)
                                }
                                Spacer()
                                if let difficulty = rack.drillDifficulty {
                                    Text(DrillDifficultyLevel(rawValue: difficulty)?.label ?? difficulty)
                                        .font(.caption2.weight(.semibold))
                                        .foregroundColor(Theme.muted)
                                        .lineLimit(1)
                                }
                            }
                            if let tags = rack.drillTags, !tags.isEmpty {
                                HStack(spacing: 5) {
                                    ForEach(tags, id: \.self) { tag in
                                        badge(text: tag, color: Theme.teal)
                                    }
                                }
                            }
                        }
                        .padding(9)
                        .background(Theme.panel2.opacity(0.65))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
    }

    private var errorsSection: some View {
        let rs = session.racks
        return SectionCard(title: "Unforced errors") {
            LazyVGrid(columns: Layout.fourColumn(), spacing: 8) {
                MiniStatCard(label: "Miss", value: "\(rs.reduce(0) { $0 + $1.missCount })")
                MiniStatCard(label: "Pos", value: "\(rs.reduce(0) { $0 + $1.positionTrackingCount })")
                MiniStatCard(label: "Safety", value: "\(rs.reduce(0) { $0 + $1.safetyCount })")
                MiniStatCard(label: "Pattern", value: "\(rs.reduce(0) { $0 + $1.patternMistakeCount })")
            }
        }
    }

    private var breaksSection: some View {
        let rs = session.racks
        let n = Double(max(rs.count, 1))
        let myB = rs.filter { $0.breaker == "me" }.count
        let dryB = rs.filter { $0.breaker == "me" && $0.breakBalls == 0 }.count
        let rus = rs.filter { $0.outcome == "runout" && $0.result == "won" }.count
        let oRus = rs.filter { $0.outcome == "runout" && $0.result == "lost" }.count
        let bnr = rs.filter { $0.breakAndRun }.count
        let avgP = rs.isEmpty ? 0 : Double(rs.reduce(0) { $0 + Analytics.ep($1, game: session.game) }) / n

        var rows: [(String, String)] = [
            ("Dry breaks", myB == 0 ? "—" : "\(dryB)/\(myB)"),
            ("Runouts", "\(rus)")
        ]
        if session.isPractice {
            let errTotal = rs.reduce(0) { $0 + $1.unforcedErrorCount }
            rows.append(("Err/rack", String(format: "%.1f", Double(errTotal) / n)))
        } else {
            rows.append(("Opp runouts", "\(oRus)"))
        }
        rows.append(("B&R", "\(bnr)"))
        rows.append(("Avg potted", String(format: "%.1f", avgP)))

        return SectionCard(title: "Break") {
            LazyVGrid(columns: Layout.fourColumn(), spacing: 8) {
                ForEach(rows, id: \.0) { item in
                    MiniStatCard(label: item.0, value: item.1)
                }
            }
        }
    }

    private var rackLogSection: some View {
        let rs = session.racks
        return SectionCard(title: "Rack log") {
            VStack(spacing: 8) {
                ForEach(Array(rs.enumerated()), id: \.offset) { idx, r in
                    let err = r.unforcedErrorCount
                    HStack(spacing: 8) {
                        Text("\(idx + 1)")
                            .font(.caption)
                            .foregroundColor(Theme.muted)
                            .frame(width: 20, alignment: .leading)
                        Text(session.isPractice ? "Prac" : (r.result == "won" ? "Won" : "Lost"))
                            .font(.caption)
                            .foregroundColor(r.result == "won" ? Theme.teal : (r.result == "lost" ? Theme.red : Theme.amber))
                            .frame(width: 40, alignment: .leading)
                        Text(outcomeLabel(r.outcome))
                            .font(.caption)
                            .foregroundColor(Theme.purple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.panel2)
                            .cornerRadius(4)
                        Text("\(err) ue")
                            .font(.caption2)
                            .foregroundColor(Theme.muted)
                        Spacer()
                        if r.breakAndRun {
                            Text("B&R")
                                .font(.caption2)
                                .foregroundColor(Theme.amber)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func metaText() -> String {
        let opponent = session.isPractice ? "" : session.opponent.trimmingCharacters(in: .whitespaces)
        let oppText = opponent.isEmpty ? nil : "vs \(opponent)"
        let countText = session.isDrillPractice ? "\(session.drillAttempts) attempts" : "\(session.racks.count) racks"
        return [session.typeLabel, session.isDrillPractice ? session.drillTitle : session.gameLabel, oppText, countText, session.drillTargetLabel, AppFormatters.sessionDate(session.ts)]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    private func badge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(color.opacity(0.28), lineWidth: 0.5))
            .cornerRadius(5)
    }

    private func outcomeLabel(_ outcome: String?) -> String {
        switch outcome {
        case "runout": return "Runout"
        case "noRunout": return "No runout"
        case "safety": return "Safety"
        case "error": return "Error"
        case "other": return "Other"
        default: return "—"
        }
    }

    private func saveLabel() {
        let trimmed = labelText.trimmingCharacters(in: .whitespaces)
        Task { await store.updateSessionLabel(sessionID: session.id, label: trimmed) }
    }

    private func savePerformanceRating(_ rating: Int) {
        Task { await store.updateSessionMeta(sessionID: session.id, performanceRating: rating) }
    }

    private func saveOpponent() {
        Task { await store.updateSessionMeta(sessionID: session.id, opponent: opponentText.trimmingCharacters(in: .whitespaces)) }
    }

    private var opponentSuggestions: [String] {
        let names = opponentStore.availableNames(from: store.sessions)
            .filter { $0 != "All opponents" }
        let current = opponentText.trimmingCharacters(in: .whitespacesAndNewlines)
        return names.filter { current.isEmpty || $0 != current }
    }
}

private extension UIColor {
    var rgbaComponents: (r: Double, g: Double, b: Double, a: Double) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
    }
}
