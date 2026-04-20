import SwiftUI

struct SummaryView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.horizontalSizeClass) private var hSizeClass

    let session: Session
    @State private var labelText: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header
                summaryCards
                errorsSection
                missesSection
                breaksSection
                rackLogSection
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(Theme.bg)
        .navigationTitle("Summary")
        .onAppear { labelText = session.label }
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

    private var errorsSection: some View {
        let rs = session.racks
        func sum(_ key: KeyPath<Rack, Int>) -> Int { rs.reduce(0) { $0 + $1[keyPath: key] } }
        return SectionCard(title: "Mistakes") {
            LazyVGrid(columns: Layout.columns(hSizeClass: hSizeClass), spacing: Layout.gridSpacing) {
                StatCard(label: "Fouls", value: "\(sum(\.fouls))")
                StatCard(label: "Bad safety", value: "\(sum(\.badSafety))")
                StatCard(label: "Bad pos", value: "\(sum(\.badPosition))")
                StatCard(label: "Pattern", value: "\(sum(\.planChange))")
            }
        }
    }

    private var missesSection: some View {
        let rs = session.racks
        let total = rs.reduce(0) { $0 + $1.missCount }
        return SectionCard(title: "Misses") {
            LazyVGrid(columns: Layout.columns(hSizeClass: hSizeClass), spacing: Layout.gridSpacing) {
                StatCard(label: "Miss", value: "\(total)")
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
                        Text("\(err) err")
                            .font(.caption2)
                            .foregroundColor(Theme.muted)
                        Spacer()
                        Text("\(r.missCount) miss")
                            .font(.caption2)
                            .foregroundColor(Theme.muted)
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
        "\(session.typeLabel) · \(session.gameLabel) · \(session.racks.count) racks · \(AppFormatters.sessionDate(session.ts))"
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
}
