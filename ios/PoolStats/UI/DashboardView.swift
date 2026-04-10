import SwiftUI
import Charts
import UniformTypeIdentifiers

struct DashboardView: View {
    @EnvironmentObject private var store: DataStore
    @State private var timeFilter: TimeFilter = .all
    @State private var mode: ModeFilter = .all
    @State private var shotGame: String = "8ball"
    @State private var wlGame: String = "8ball"
    @State private var outcomeTarget: OutcomeTarget = .match
    @State private var showExporter: Bool = false
    @State private var showImporter: Bool = false
    @State private var exportDocument = JSONDocument(data: Data())
    @State private var pendingImportData: Data?
    @State private var pendingImportCount: Int = 0
    @State private var showImportConfirm: Bool = false
    @State private var showImportError: Bool = false

    private let shotColors: [Color] = [Theme.red, Theme.red, Theme.amber, Theme.blue, Theme.teal, Theme.purple, Theme.green]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    headerFilters
                    statGrid
                    if !isPracticeMode { trendSection }
                    mistakesSection
                    if !isPracticeMode { wlSection }
                    if !isPracticeMode { outcomesSection }
                    skillSection
                    if !isPracticeMode { fargoSection }
                    insightsSection
                    exportImportSection
                }
                .padding(.horizontal, 14)
                .padding(.top, 4)
                .padding(.bottom, 10)
            }
            .background(Theme.bg)
            .navigationTitle("Pool Stats")
            .navigationBarTitleDisplayMode(.inline)
        }
        .fileExporter(isPresented: $showExporter, document: exportDocument, contentType: .json, defaultFilename: "pool.json") { _ in }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                if let data = try? Data(contentsOf: url) {
                    if let sessions = try? JSONTransfer.importSessions(data) {
                        pendingImportData = data
                        pendingImportCount = sessions.count
                        showImportConfirm = true
                    } else {
                        showImportError = true
                    }
                }
            case .failure:
                break
            }
        }
        .alert("Replace all data?", isPresented: $showImportConfirm) {
            Button("Replace", role: .destructive) {
                if let data = pendingImportData {
                    Task { await store.importJSON(data) }
                }
                pendingImportData = nil
            }
            Button("Cancel", role: .cancel) {
                pendingImportData = nil
            }
        } message: {
            Text("Replace all data with \(pendingImportCount) sessions?")
        }
        .alert("Import failed.", isPresented: $showImportError) {
            Button("OK", role: .cancel) { }
        }
    }

    private var filteredSessions: [Session] {
        Analytics.filteredSessions(store.sessions, timeFilter: timeFilter, mode: mode)
    }

    private var allRacks: [Rack] {
        Analytics.filteredRacks(filteredSessions)
    }

    private var matchSessions: [Session] {
        Analytics.matchOnly(filteredSessions)
    }

    private var matchRacks: [Rack] {
        Analytics.matchRacks(filteredSessions)
    }

    private var isPracticeMode: Bool {
        mode == .practice
    }

    private var headerFilters: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(TimeFilter.allCases) { f in
                        PillButton(label: f.label, isOn: f == timeFilter) {
                            timeFilter = f
                        }
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(ModeFilter.allCases) { m in
                        PillButton(label: m.label, isOn: m == mode) {
                            mode = m
                        }
                    }
                }
            }
        }
    }

    private var statGrid: some View {
        let sessionsCount = filteredSessions.count
        let racksCount = allRacks.count
        let matchWin = matchWinPercentText()
        let rackWin = rackWinPercentText()

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
            StatCard(label: "Sessions", value: sessionsCount == 0 ? "—" : String(sessionsCount))
            StatCard(label: "Racks", value: racksCount == 0 ? "—" : String(racksCount))
            StatCard(label: "Match win%", value: isPracticeMode ? "—" : matchWin)
            StatCard(label: "Rack win%", value: isPracticeMode ? "—" : rackWin)
        }
    }

    private var trendSection: some View {
        let series = Analytics.trendSeries(sessions: matchSessions, timeFilter: timeFilter)
        return SectionCard(title: "Win rate over time") {
            if series.labels.isEmpty {
                Text("Not enough data")
                    .font(.caption)
                    .foregroundColor(Theme.muted)
            } else {
                let count = series.labels.count
                let tickStep = max(1, count / 6)
                let ticks = stride(from: 0, to: count, by: tickStep).map { $0 }
                Chart {
                    ForEach(Array(series.labels.enumerated()), id: \.offset) { idx, label in
                        if let v = series.match[idx] {
                            LineMark(x: .value("Index", idx), y: .value("Match", v))
                                .foregroundStyle(Theme.purple)
                                .symbol(Circle())
                                .interpolationMethod(.catmullRom)
                        }
                        if let v = series.rack[idx] {
                            LineMark(x: .value("Index", idx), y: .value("Rack", v))
                                .foregroundStyle(Theme.teal)
                                .symbol(Circle())
                                .interpolationMethod(.catmullRom)
                        }
                    }
                }
                .chartXScale(domain: 0...(max(0, count - 1)))
                .chartXAxis {
                    AxisMarks(values: ticks) { value in
                        if let idx = value.as(Int.self), idx >= 0, idx < series.labels.count {
                            AxisValueLabel {
                                Text(series.labels[idx])
                            }
                        }
                    }
                }
                .frame(height: 180)
            }
        }
    }

    private var mistakesSection: some View {
        let racks = Analytics.filteredRacks(filteredSessions, game: shotGame)
        let items = Analytics.mistakesPerRack(racks).sorted { $0.value > $1.value }
        return SectionCard(title: "Mistakes per rack") {
            HStack(spacing: 6) {
                PillButton(label: "8-ball", isOn: shotGame == "8ball") { shotGame = "8ball" }
                PillButton(label: "9-ball", isOn: shotGame == "9ball") { shotGame = "9ball" }
            }
            Chart {
                ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                    BarMark(
                        x: .value("Label", item.label),
                        y: .value("Value", item.value)
                    )
                    .foregroundStyle(shotColors[idx % shotColors.count])
                    .cornerRadius(4)
                }
            }
            .frame(height: 200)
        }
    }

    private var wlSection: some View {
        let racks = Analytics.matchRacks(filteredSessions, game: wlGame)
        let result = Analytics.wonLostItems(racks)
        return SectionCard(title: "Mistakes: won vs lost") {
            HStack(spacing: 6) {
                PillButton(label: "8-ball", isOn: wlGame == "8ball") { wlGame = "8ball" }
                PillButton(label: "9-ball", isOn: wlGame == "9ball") { wlGame = "9ball" }
            }
            Chart {
                ForEach(result.items) { item in
                    BarMark(
                        x: .value("Label", item.label),
                        y: .value("Won", item.won)
                    )
                    .foregroundStyle(Theme.teal)
                    .position(by: .value("Type", "Won"))
                    BarMark(
                        x: .value("Label", item.label),
                        y: .value("Lost", item.lost)
                    )
                    .foregroundStyle(Theme.red)
                    .position(by: .value("Type", "Lost"))
                }
            }
            .frame(height: 220)
            Text(result.lossText)
                .font(.caption)
                .foregroundColor(Theme.muted)
        }
    }

    private var outcomesSection: some View {
        let counts = Analytics.outcomeCounts(sessions: filteredSessions, target: outcomeTarget)
        return SectionCard(title: "Outcomes") {
            HStack(spacing: 6) {
                PillButton(label: "Match", isOn: outcomeTarget == .match) { outcomeTarget = .match }
                PillButton(label: "Rack", isOn: outcomeTarget == .rack) { outcomeTarget = .rack }
            }
            HStack(spacing: 16) {
                RingChart(wins: counts.wins, losses: counts.losses)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Wins (\(counts.wins))")
                        .font(.caption)
                        .foregroundColor(Theme.teal)
                    Text("Losses (\(counts.losses))")
                        .font(.caption)
                        .foregroundColor(Theme.red)
                }
                Spacer()
            }
        }
    }

    private var skillSection: some View {
        let scores = Analytics.radarScores(allSessions: filteredSessions, filteredRacks: allRacks, mode: mode)
        let labels = ["Potting", "Position", "Safety", "Fouls", "Consistency"]
        let colors: [Color] = [Theme.purple, Theme.teal, Theme.green, Theme.red, Theme.blue]
        return SectionCard(title: "Skill breakdown") {
            VStack(spacing: 16) {
                RadarChart(labels: labels, values: scores, color: Theme.purple)
                    .frame(height: 240)
                VStack(spacing: 14) {
                    ForEach(Array(labels.enumerated()), id: \.offset) { idx, label in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(label)
                                    .font(.callout)
                                    .foregroundColor(Theme.text2)
                                Spacer()
                                Text("\(scores[idx])")
                                    .font(.callout)
                                    .foregroundColor(colors[idx])
                            }
                            PercentageBar(value: scores[idx], color: colors[idx], height: 8)
                        }
                    }
                }
            }
        }
    }

    private var fargoSection: some View {
        let fargo = Analytics.fargoResult(matchSessions: matchSessions)
        return SectionCard(title: "Fargo estimate") {
            Text(fargo.rangeText)
                .font(.largeTitle)
                .foregroundColor(Theme.purple)
            VStack(spacing: 8) {
                ForEach(fargo.factors) { f in
                    HStack {
                        Text(f.name)
                            .font(.caption)
                            .foregroundColor(Theme.text2)
                        Text(f.valueText)
                            .font(.caption2)
                            .foregroundColor(Theme.muted)
                        Spacer()
                        Text(f.weightText)
                            .font(.caption2)
                            .foregroundColor(Theme.muted)
                        Text("\(f.contribution >= 0 ? "+" : "")\(f.contribution)")
                            .font(.caption)
                            .foregroundColor(f.contribution >= 3 ? Theme.teal : (f.contribution <= -3 ? Theme.red : Theme.muted))
                    }
                }
            }
        }
    }

    private var insightsSection: some View {
        let insights = Analytics.insights(allRacks: allRacks, matchRacks: matchRacks)
        let layoutLabels = ["Open", "Clustered", "Problematic", "Snookered"]
        return SectionCard(title: "Break & layout insights") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                ForEach(insights.breakCards, id: \.0) { item in
                    StatCard(label: item.0, value: item.1 != nil ? "\(item.1!)%" : "—")
                }
            }
            Chart {
                ForEach(Array(layoutLabels.enumerated()), id: \.offset) { idx, label in
                    let v = insights.layoutRates[idx] ?? 0
                    BarMark(
                        x: .value("Win", v),
                        y: .value("Layout", label)
                    )
                    .foregroundStyle(colorForLayout(idx))
                }
            }
            .frame(height: 180)
        }
    }

    private var exportImportSection: some View {
        HStack(spacing: 10) {
            Button("↓ Export JSON") {
                if let data = store.exportJSON() {
                    exportDocument = JSONDocument(data: data)
                    showExporter = true
                }
            }
            .buttonStyle(.bordered)

            Button("↑ Import JSON") {
                showImporter = true
            }
            .buttonStyle(.bordered)
        }
    }

    private func matchWinPercentText() -> String {
        let m = matchSessions
        if m.isEmpty { return "—" }
        let wins = m.filter { s in
            let w = s.racks.filter { $0.result == "won" }.count
            return w > s.racks.count / 2
        }.count
        return "\(Int(round(Double(wins) / Double(m.count) * 100)))%"
    }

    private func rackWinPercentText() -> String {
        let r = matchRacks
        if r.isEmpty { return "—" }
        let wins = r.filter { $0.result == "won" }.count
        return "\(Int(round(Double(wins) / Double(r.count) * 100)))%"
    }

    private func colorForLayout(_ idx: Int) -> Color {
        switch idx {
        case 0: return Theme.teal
        case 1: return Theme.amber
        case 2: return Theme.red
        default: return Theme.purple
        }
    }
}
