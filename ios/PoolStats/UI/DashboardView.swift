import SwiftUI
import Charts
import UniformTypeIdentifiers

struct DashboardView: View {
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var profileStore: PlayerProfileStore
    @State private var timeFilter: TimeFilter = .all
    @State private var mode: ModeFilter = .all
    @State private var activePickerID: String? = nil
    @State private var shotGame: String = "8ball"
    @State private var wlGame: String = "8ball"
    @State private var showExporter: Bool = false
    @State private var showImporter: Bool = false
    @State private var exportDocument = JSONDocument(data: Data())
    @State private var pendingImportData: Data?
    @State private var pendingImportCount: Int = 0
    @State private var showImportConfirm: Bool = false
    @State private var showImportError: Bool = false
    @State private var showFargoInfo: Bool = false

    @Environment(\.horizontalSizeClass) private var hSizeClass
    private let shotColors: [Color] = [Theme.red, Theme.red, Theme.amber, Theme.blue, Theme.teal, Theme.purple, Theme.green]

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 12) {
                    header
                    headerFilters
                    statGrid
                    if !isPracticeMode { recentFormSection }
                    activitySection
                    if !isPracticeMode { trendSection }
                    mistakesSection
                    errorTrendSection
                    if !isPracticeMode { wlSection }
                    if !isPracticeMode { outcomesSection }
                    skillSection
                    insightsSection
                    exportImportSection
                }
                .padding(.horizontal, Layout.pagePadding)
                .padding(.top, 0)
                .padding(.bottom, 10)
            }
            pickerOverlay
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
        .alert("Fargo Estimate", isPresented: $showFargoInfo) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text("Fargo is a skill rating system for pool players. This visual blends your baseline Fargo with tracked match performance, then scores five areas: potting, position, pattern, runout, and overall.")
        }
    }

    @ViewBuilder
    private var pickerOverlay: some View {
        if activePickerID == "dashboard.time" {
            OverlayPickerPanel(title: "Time",
                               items: TimeFilter.allCases,
                               selection: $timeFilter,
                               label: { $0.label },
                               onDismiss: { activePickerID = nil })
        } else if activePickerID == "dashboard.mode" {
            OverlayPickerPanel(title: "Mode",
                               items: ModeFilter.allCases,
                               selection: $mode,
                               label: { $0.label },
                               onDismiss: { activePickerID = nil })
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
        HStack(spacing: 8) {
            InlinePickerCard(id: "dashboard.time",
                             title: "Time",
                             items: TimeFilter.allCases,
                             selection: $timeFilter,
                             activeID: $activePickerID) { $0.label }
            InlinePickerCard(id: "dashboard.mode",
                             title: "Mode",
                             items: ModeFilter.allCases,
                             selection: $mode,
                             activeID: $activePickerID) { $0.label }
        }
    }

    private var statGrid: some View {
        let sessionsCount = filteredSessions.count
        let racksCount = allRacks.count

        return HStack(spacing: 8) {
            DashboardKPI(label: "Sessions", value: sessionsCount == 0 ? "—" : String(sessionsCount))
            DashboardKPI(label: "Racks", value: racksCount == 0 ? "—" : String(racksCount))
        }
    }

    private var recentFormSection: some View {
        let recent = Array(filteredSessions.filter { $0.type == "match" }.sorted { $0.ts > $1.ts }.prefix(10))
        let wins = recent.filter { $0.wins > $0.losses }.count
        let draws = recent.filter { $0.wins == $0.losses }.count
        let losses = recent.filter { $0.losses > $0.wins }.count
        let recordText = recent.isEmpty ? "No matches yet" : "\(wins)W \(draws)D \(losses)L"
        let subtitle = recent.isEmpty ? "No match results in current filters" : "Last \(recent.count) match results"

        return SectionCard(title: "Recent form") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                    Spacer(minLength: 8)
                    Text(recordText)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(recent.isEmpty ? Theme.muted : Theme.text2)
                }

                if recent.isEmpty {
                    Text("Log a few matches and your form will appear here.")
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    RecentFormVisual(sessions: Array(recent.reversed()))
                    RecentOutcomeMixBar(wins: wins, draws: draws, losses: losses)
                    HStack {
                        Text("Outcome mix")
                            .font(.caption2)
                            .foregroundColor(Theme.text2)
                        Spacer(minLength: 8)
                        Text("Wins · Draws · Losses")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(Theme.text2)
                    }
                }
            }
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
        let match = Analytics.outcomeCounts(sessions: filteredSessions, target: .match)
        let rack = Analytics.outcomeCounts(sessions: filteredSessions, target: .rack)
        return SectionCard(title: "Outcomes") {
            DoubleRingChart(
                outerWins: match.wins, outerTotal: match.wins + match.losses,
                innerWins: rack.wins, innerTotal: rack.wins + rack.losses
            )
        }
    }

    private var skillSection: some View {
        let fargo = Analytics.fargoResult(matchSessions: matchSessions)
        let labels = fargo.factors.map(\.name)
        let scores = fargo.factors.map(\.scoreValue)
        let colors: [Color] = [Theme.purple, Theme.teal, Theme.green, Theme.red, Theme.blue]
        let baseline = profileStore.profile.clampedBaseline
        let performanceCenter = fargo.estimatedScore
        let confidence = min(max(Double(matchRacks.count) / 200.0, 0), 1)
        let blended = Int(round(Double(baseline) * (1 - confidence) + Double(performanceCenter) * confidence))
        let blendedRange = "\(blended - 25)–\(blended + 25)"
        return SectionCard(title: "Skill breakdown") {
            VStack(spacing: 16) {
                RadarChart(labels: labels, values: scores, color: Theme.purple)
                    .frame(height: Layout.chartHeight(Layout.chartRadar, hSizeClass: hSizeClass))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Fargo estimate")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Theme.text2)
                        Button {
                            showFargoInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(Theme.muted)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    Text(blendedRange)
                        .font(.title2.weight(.semibold))
                        .foregroundColor(Theme.purple)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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

    private var activityActiveDays: Int {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: Date())
        let daysToSunday = (weekday - cal.firstWeekday + 7) % 7
        let sunday = cal.date(byAdding: .day, value: -daysToSunday, to: Date())!
        let start = cal.startOfDay(for: cal.date(byAdding: .day, value: -17 * 7, to: sunday)!)
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return Set(store.sessions.compactMap { s -> String? in
            guard cal.startOfDay(for: s.ts) >= start else { return nil }
            return fmt.string(from: s.ts)
        }).count
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Training activity")
                    .font(.subheadline)
                    .foregroundColor(Theme.text2)
                Spacer(minLength: 0)
                Text("\(activityActiveDays) active days")
                    .font(.caption2)
                    .foregroundColor(Theme.muted)
            }
            ActivityHeatmapView(sessions: store.sessions)
        }
        .padding(14)
        .background(Theme.panel)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
    }

    private var errorTrendSection: some View {
        SectionCard(title: "Error composition trend") {
            ErrorTrendChart(data: errorStackData, chartHeight: Layout.chartHeight(Layout.chartMd, hSizeClass: hSizeClass))
        }
    }

    private var errorStackData: [ErrorStackPoint] {
        let sorted = filteredSessions.sorted { $0.ts < $1.ts }
        guard sorted.count >= 3 else { return [] }
        let recent = Array(sorted.suffix(30))

        func perRack(_ kp: KeyPath<Rack, Int>, _ s: Session) -> Double {
            guard !s.racks.isEmpty else { return 0 }
            return Double(s.racks.reduce(0) { $0 + $1[keyPath: kp] }) / Double(s.racks.count)
        }

        func rolling(_ vals: [Double]) -> [Double] {
            vals.enumerated().map { i, _ in
                let start = max(0, i - 4)
                let slice = vals[start...i]
                return slice.reduce(0, +) / Double(slice.count)
            }
        }

        let miss = rolling(recent.map { perRack(\.missCount, $0) })
        let pos  = rolling(recent.map { perRack(\.positionTrackingCount, $0) })
        let saf  = rolling(recent.map { perRack(\.safetyCount, $0) })
        let pattern = rolling(recent.map { perRack(\.patternMistakeCount, $0) })

        return recent.enumerated().flatMap { i, session in
            let m = miss[i]; let p = pos[i]; let s = saf[i]; let pat = pattern[i]
            return [
                ErrorStackPoint(id: "\(session.id)-m", sessionIndex: i, bottom: 0,         top: m,             type: "Miss"),
                ErrorStackPoint(id: "\(session.id)-p", sessionIndex: i, bottom: m,         top: m + p,         type: "Position"),
                ErrorStackPoint(id: "\(session.id)-s", sessionIndex: i, bottom: m + p,     top: m + p + s,     type: "Safety"),
                ErrorStackPoint(id: "\(session.id)-pat", sessionIndex: i, bottom: m + p + s, top: m + p + s + pat, type: "Pattern")
            ]
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

private struct DashboardKPI: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.callout)
                .foregroundColor(Theme.muted)
            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Theme.text)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background(Theme.panel)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
    }
}

private struct RecentFormVisual: View {
    let sessions: [Session]

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(sessions, id: \.sessionUUID) { session in
                VStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(color(for: session).opacity(0.24))
                        .frame(width: 26, height: height(for: session))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(color(for: session).opacity(0.8), lineWidth: 1)
                        )
                        .overlay {
                            Text(label(for: session))
                                .font(.caption2.weight(.black))
                                .foregroundColor(color(for: session))
                        }
                    Circle()
                        .fill(color(for: session).opacity(0.9))
                        .frame(width: 4, height: 4)
                }
                .frame(maxWidth: .infinity)
                .accessibilityLabel(accessibilityLabel(for: session))
            }
        }
        .padding(.top, 2)
    }

    private func label(for session: Session) -> String {
        if session.wins == session.losses { return "D" }
        return session.wins > session.losses ? "W" : "L"
    }

    private func color(for session: Session) -> Color {
        if session.wins == session.losses { return Theme.amber }
        return session.wins > session.losses ? Theme.green : Theme.red
    }

    private func height(for session: Session) -> CGFloat {
        if session.wins == session.losses { return 32 }
        let diff = min(abs(session.wins - session.losses), 5)
        return CGFloat(32 + diff * 5)
    }

    private func accessibilityLabel(for session: Session) -> String {
        let score = "\(session.wins) to \(session.losses)"
        if session.wins == session.losses { return "Draw match, \(score)" }
        return session.wins > session.losses ? "Match win, \(score)" : "Match loss, \(score)"
    }
}

private struct RecentOutcomeMixBar: View {
    let wins: Int
    let draws: Int
    let losses: Int

    private var total: Int { wins + draws + losses }

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                segment(count: wins, color: Theme.green, width: geo.size.width)
                segment(count: draws, color: Theme.amber, width: geo.size.width)
                segment(count: losses, color: Theme.red, width: geo.size.width)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(Theme.panel2.opacity(0.95))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Theme.border, lineWidth: 0.5))
        }
        .frame(height: 8)
        .accessibilityLabel("\(wins) wins, \(draws) draws, \(losses) losses")
    }

    @ViewBuilder
    private func segment(count: Int, color: Color, width: CGFloat) -> some View {
        if total > 0, count > 0 {
            Rectangle()
                .fill(color.opacity(0.9))
                .frame(width: width * CGFloat(count) / CGFloat(total))
        }
    }
}

private struct ErrorStackPoint: Identifiable {
    let id: String
    let sessionIndex: Int
    let bottom: Double
    let top: Double
    let type: String
}

private struct ErrorTrendChart: View {
    let data: [ErrorStackPoint]
    let chartHeight: CGFloat

    var body: some View {
        if data.isEmpty {
            Text("Need 3+ sessions to show trend")
                .font(.caption)
                .foregroundColor(Theme.muted)
        } else {
            chartBody
            Text("Errors per rack · 5-session rolling avg")
                .font(.caption2)
                .foregroundColor(Theme.muted)
        }
    }

    private var chartBody: some View {
        Chart(data) { point in
            AreaMark(
                x: .value("Session", point.sessionIndex),
                yStart: .value("Bottom", point.bottom),
                yEnd: .value("Top", point.top)
            )
            .foregroundStyle(by: .value("Error", point.type))
            .interpolationMethod(.monotone)
        }
        .chartForegroundStyleScale(
            domain: ["Miss", "Position", "Safety", "Pattern"],
            range: [Theme.red, Theme.amber, Theme.teal, Theme.purple]
        )
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { v in
                AxisGridLine()
                AxisValueLabel {
                    if let idx = v.as(Int.self) {
                        Text("S\(idx + 1)").font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { v in
                AxisGridLine()
                AxisValueLabel {
                    if let val = v.as(Double.self) {
                        Text(String(format: "%.1f", val)).font(.caption2)
                    }
                }
            }
        }
        .chartLegend(position: .bottom, alignment: .leading, spacing: 8)
        .frame(height: chartHeight)
    }
}

private struct ActivityHeatmapView: View {
    let sessions: [Session]

    private let cellSpacing: CGFloat = 2
    private let weeks = 18
    private let days = 7

    // Card content width = screen width − page padding (14×2) − card padding (14×2)
    // 22pt reserved on left for "week" label (18pt) + HStack gap (4pt)
    private var cellSize: CGFloat {
        let cardWidth = UIScreen.main.bounds.width - 56
        return max(8, (cardWidth - 22 + cellSpacing) / CGFloat(weeks) - cellSpacing)
    }

    private var gridHeight: CGFloat {
        CGFloat(days) * (cellSize + cellSpacing) - cellSpacing
    }

    private var byDate: [String: Int] {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        var d: [String: Int] = [:]
        for s in sessions {
            let key = fmt.string(from: s.ts)
            d[key, default: 0] += 1
        }
        return d
    }

    private var startDate: Date {
        let now = Date()
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: now)
        let daysToSunday = (weekday - cal.firstWeekday + 7) % 7
        let sunday = cal.date(byAdding: .day, value: -daysToSunday, to: now)!
        return cal.startOfDay(for: cal.date(byAdding: .day, value: -(weeks - 1) * 7, to: sunday)!)
    }

    private func date(week: Int, day: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: week * 7 + day, to: startDate)!
    }

    private func dateKey(_ d: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: d)
    }

    private func cellColor(count: Int) -> Color {
        switch count {
        case 0: return Theme.panel2
        case 1: return Theme.purple.opacity(0.35)
        case 2: return Theme.purple.opacity(0.6)
        default: return Theme.purple
        }
    }

    private var monthLabels: [(text: String, col: Int)] {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"
        var labels: [(String, Int)] = []
        var lastMonth = -1
        for w in 0..<weeks {
            let d = date(week: w, day: 0)
            let m = cal.component(.month, from: d)
            if m != lastMonth {
                labels.append((fmt.string(from: d), w))
                lastMonth = m
            }
        }
        return labels
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            monthRow
            HStack(alignment: .top, spacing: 4) {
                weekLabel
                grid
            }
        }
    }

    private var monthRow: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 18)
            ZStack(alignment: .leading) {
                Color.clear.frame(height: 14)
                ForEach(monthLabels, id: \.col) { item in
                    Text(item.text)
                        .font(.system(size: 9))
                        .foregroundColor(Theme.muted)
                        .offset(x: CGFloat(item.col) * (cellSize + cellSpacing))
                }
            }
        }
    }

    private var weekLabel: some View {
        ZStack {
            Color.clear.frame(width: 18, height: gridHeight)
            Text("week")
                .font(.system(size: 11))
                .foregroundColor(Theme.muted)
                .rotationEffect(.degrees(-90))
                .fixedSize()
        }
    }

    private var grid: some View {
        HStack(spacing: cellSpacing) {
            ForEach(0..<weeks, id: \.self) { w in
                VStack(spacing: cellSpacing) {
                    ForEach(0..<days, id: \.self) { d in
                        let dt = date(week: w, day: d)
                        let count = byDate[dateKey(dt), default: 0]
                        let isFuture = dt > Date()
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isFuture ? Color.clear : cellColor(count: count))
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
    }

}
