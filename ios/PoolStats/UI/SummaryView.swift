import SwiftUI

struct SummaryView: View {
    @EnvironmentObject private var store: DataStore

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
        let won = rs.filter { $0.result == "won" }.count
        let runouts = rs.filter { $0.outcome == "runout" }.count
        let errTotal = rs.reduce(0) { $0 + errCount($1) }

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
                ("Won", "\(won)"),
                ("Lost", "\(rs.count - won)"),
                ("Win%", rs.isEmpty ? "—" : "\(Int(round(Double(won) / Double(rs.count) * 100)))%")
            ]
        }

        return SectionCard(title: "Summary") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
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
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                StatCard(label: "Fouls", value: "\(sum(\.fouls))")
                StatCard(label: "Bad safety", value: "\(sum(\.badSafety))")
                StatCard(label: "Bad pos", value: "\(sum(\.badPosition))")
                StatCard(label: "Pattern", value: "\(sum(\.planChange))")
            }
        }
    }

    private var missesSection: some View {
        let rs = session.racks
        let easy = rs.reduce(0) { $0 + $1.missEasy }
        let med = rs.reduce(0) { $0 + $1.missMed }
        let hard = rs.reduce(0) { $0 + $1.missHard }
        let total = easy + med + hard
        return SectionCard(title: "Misses") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                StatCard(label: "Easy", value: "\(easy)")
                StatCard(label: "Medium", value: "\(med)")
                StatCard(label: "Hard", value: "\(hard)")
                StatCard(label: "Total", value: "\(total)")
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
            let errTotal = rs.reduce(0) { $0 + errCount($1) }
            rows.append(("Err/rack", String(format: "%.1f", Double(errTotal) / n)))
        } else {
            rows.append(("Opp runouts", "\(oRus)"))
        }
        rows.append(("B&R", "\(bnr)"))
        rows.append(("Avg potted", String(format: "%.1f", avgP)))

        return SectionCard(title: "Break") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
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
                    let err = errCount(r)
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
                        Text("\(r.missEasy)E \(r.missMed)M \(r.missHard)H")
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
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "MMM d, yyyy"
        let date = df.string(from: session.ts)
        let game = session.game == "8ball" ? "8-ball" : "9-ball"
        let type = session.isPractice ? "Practice" : "Match"
        return "\(type) · \(game) · \(session.racks.count) racks · \(date)"
    }

    private func outcomeLabel(_ outcome: String?) -> String {
        switch outcome {
        case "runout": return "Runout"
        case "safety": return "Safety"
        case "error": return "Error"
        case "other": return "Other"
        default: return "—"
        }
    }

    private func errCount(_ r: Rack) -> Int {
        r.fouls + r.badSafety + r.badPosition + r.planChange + r.missEasy + r.missMed + r.missHard
    }

    private func saveLabel() {
        let trimmed = labelText.trimmingCharacters(in: .whitespaces)
        Task { await store.updateSessionLabel(sessionID: session.id, label: trimmed) }
    }
}
