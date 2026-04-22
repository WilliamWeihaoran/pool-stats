import SwiftUI
import UIKit

struct SummaryView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.horizontalSizeClass) private var hSizeClass

    let session: Session
    @State private var labelText: String = ""
    @State private var performanceRating: Int? = nil
    @State private var performanceValue: Int = 5

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header
                timeSection
                performanceSection
                summaryCards
                errorsSection
                breaksSection
                rackLogSection
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(Theme.bg)
        .navigationTitle("Summary")
        .onAppear {
            labelText = session.label
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
                ("Err/rack", String(format: "%.1f", Double(errTotal) / n))
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
            LazyVGrid(columns: Layout.columns(hSizeClass: hSizeClass), spacing: Layout.gridSpacing) {
                ForEach(top, id: \.0) { item in
                    StatCard(label: item.0, value: item.1)
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

        return SectionCard(title: "Time") {
            VStack(alignment: .leading, spacing: 10) {
                LazyVGrid(columns: Layout.columns(hSizeClass: hSizeClass), spacing: Layout.gridSpacing) {
                    StatCard(label: "Raw time", value: rawValue)
                    StatCard(label: "Adjusted time", value: adjustedValue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Avg pace")
                            .font(.caption2)
                            .foregroundColor(Theme.muted)
                        Spacer(minLength: 0)
                        Text("includes 45s setup buffer per rack")
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

    private var errorsSection: some View {
        let rs = session.racks
        return SectionCard(title: "Unforced errors") {
            LazyVGrid(columns: Layout.columns(hSizeClass: hSizeClass), spacing: Layout.gridSpacing) {
                StatCard(label: "Miss", value: "\(rs.reduce(0) { $0 + $1.missCount })")
                StatCard(label: "Positional", value: "\(rs.reduce(0) { $0 + $1.positionalCount })")
                StatCard(label: "Safety", value: "\(rs.reduce(0) { $0 + $1.safetyCount })")
                StatCard(label: "Foul", value: "\(rs.reduce(0) { $0 + $1.foulCount })")
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
            LazyVGrid(columns: Layout.columns(hSizeClass: hSizeClass), spacing: Layout.gridSpacing) {
                ForEach(rows, id: \.0) { item in
                    StatCard(label: item.0, value: item.1)
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
        let opponent = session.opponent.trimmingCharacters(in: .whitespaces)
        let oppText = opponent.isEmpty ? nil : "vs \(opponent)"
        return [session.typeLabel, session.gameLabel, oppText, "\(session.racks.count) racks", AppFormatters.sessionDate(session.ts)]
            .compactMap { $0 }
            .joined(separator: " · ")
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
