import SwiftUI
import Charts
import UniformTypeIdentifiers

struct DashboardView: View {
    @EnvironmentObject private var store: DataStore
    @State private var timeFilter: TimeFilter = .all
    @State private var mode: ModeFilter = .all
    @State private var opponentFilter: String = "All opponents"
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

    @Environment(\.horizontalSizeClass) private var hSizeClass
    private let shotColors: [Color] = [Theme.red, Theme.red, Theme.amber, Theme.blue, Theme.teal, Theme.purple, Theme.green]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header
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
            .padding(.horizontal, Layout.pagePadding)
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
        .background(Theme.bg)
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

    private var header: some View {
        HStack {
            Text("Dashboard")
                .font(.title.bold())
                .foregroundColor(Theme.text)
            Spacer(minLength: 0)
        }
        .padding(.top, 4)
        .padding(.horizontal, 2)
    }

    private var filteredSessions: [Session] {
        var rows = Analytics.filteredSessions(store.sessions, timeFilter: timeFilter, mode: mode)
        if opponentFilter != "All opponents" {
            rows = rows.filter { $0.opponent == opponentFilter }
        }
        return rows
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
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                FilterMenuButton(title: "Time", items: TimeFilter.allCases, selection: $timeFilter) { $0.label }
                FilterMenuButton(title: "Mode", items: ModeFilter.allCases, selection: $mode) { $0.label }
            }
            if !opponentOptions.isEmpty {
                FilterMenuButton(title: "Opponent", items: opponentOptions, selection: $opponentFilter) { $0 }
            }
        }
    }

    private var opponentOptions: [String] {
        let names = store.sessions
            .map(\.opponent)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let unique = Array(NSOrderedSet(array: names)) as? [String] ?? []
        return ["All opponents"] + unique
    }

    private var statGrid: some View {
        let sessionsCount = filteredSessions.count
        let racksCount = allRacks.count

        return LazyVGrid(columns: Layout.twoColumn(), spacing: Layout.gridSpacing) {
            StatCard(label: "Sessions", value: sessionsCount == 0 ? "—" : String(sessionsCount))
            StatCard(label: "Racks", value: racksCount == 0 ? "—" : String(racksCount))
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
                let points = Array(zip(series.dates, series.match)).compactMap { date, value in
                    value.map { (date, $0) }
                }
                if points.isEmpty {
                    Text("Not enough data")
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                } else {
                    let count = points.count
                    let tickStep = max(1, count / 6)
                    let tickDates = stride(from: 0, to: count, by: tickStep).map { points[$0].0 }
                    let domainStart = series.dates.first ?? points[0].0
                    let domainEnd = series.dates.last ?? points[0].0
                    Chart {
                        ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                            LineMark(x: .value("Date", point.0), y: .value("Match", point.1))
                                .foregroundStyle(Theme.purple)
                                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                                .interpolationMethod(.monotone)
                            PointMark(x: .value("Date", point.0), y: .value("Match", point.1))
                                .foregroundStyle(Theme.purple)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: tickDates) { value in
                            if let date = value.as(Date.self), let idx = series.dates.firstIndex(of: date), idx < series.labels.count {
                                AxisValueLabel {
                                    Text(series.labels[idx])
                                }
                            }
                        }
                    }
                    .chartXScale(domain: domainStart...domainEnd)
                    .frame(height: Layout.chartHeight(Layout.chartSm, hSizeClass: hSizeClass))
                }
            }
        }
    }

    private var mistakesSection: some View {
        let racks = Analytics.filteredRacks(filteredSessions, game: shotGame)
        let items = Analytics.mistakesPerRack(racks).sorted { $0.value > $1.value }
        return SectionCard(title: "Unforced errors per rack") {
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
            .frame(height: Layout.chartHeight(Layout.chartMd, hSizeClass: hSizeClass))
        }
    }

    private var wlSection: some View {
        let racks = Analytics.matchRacks(filteredSessions, game: wlGame)
        let result = Analytics.wonLostItems(racks)
        return SectionCard(title: "Unforced errors: won vs lost") {
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
            .frame(height: Layout.chartHeight(Layout.chartLg, hSizeClass: hSizeClass))
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
                    .frame(height: Layout.chartHeight(Layout.chartRadar, hSizeClass: hSizeClass))
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
        let leak = Analytics.biggestLeakSummary(matchRacks)
        return SectionCard(title: "Break & layout insights") {
            VStack(alignment: .leading, spacing: 10) {
                MiniStatCard(label: "Biggest leak", value: leak)
                LazyVGrid(columns: Layout.columns(hSizeClass: hSizeClass), spacing: Layout.gridSpacing) {
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
                .frame(height: Layout.chartHeight(Layout.chartSm, hSizeClass: hSizeClass))
            }
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
        let wins = m.filter { $0.wins > $0.racks.count / 2 }.count
        return "\(Int(round(Double(wins) / Double(m.count) * 100)))%"
    }

    private func rackWinPercentText() -> String {
        let r = matchRacks
        if r.isEmpty { return "—" }
        let wins = r.reduce(0) { $0 + ($1.result == "won" ? 1 : 0) }
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
