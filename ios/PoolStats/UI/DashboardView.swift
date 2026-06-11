import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var profileStore: PlayerProfileStore
    @EnvironmentObject private var goalsStore: GoalsStore
    @EnvironmentObject private var opponentStore: OpponentStore
    @EnvironmentObject private var socialProfileStore: SocialProfileStore
    @EnvironmentObject private var logStore: SessionLogStore
    @State private var timeFilter: TimeFilter = .all
    @State private var mode: ModeFilter = .all
    @State private var activePickerID: String? = nil
    @State private var shotGame: String = "8ball"
    @State private var wlGame: String = "8ball"
    @State private var importExportState = DashboardImportExportState()
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
                    DashboardImportExportSection(
                        onExport: presentExportSheet,
                        onImport: { importExportState.isShowingImporter = true }
                    )
                }
                .padding(.horizontal, Layout.pagePadding)
                .padding(.top, 0)
                .padding(.bottom, 10)
            }
            pickerOverlay
        }
        .background(Theme.bg)
        .dashboardImportExportPresentation(
            state: $importExportState,
            store: store,
            goalsStore: goalsStore,
            opponentStore: opponentStore,
            profileStore: profileStore,
            socialProfileStore: socialProfileStore,
            logStore: logStore
        )
        .alert(DashboardCopy.fargoInfoTitle, isPresented: $showFargoInfo) {
            Button(DashboardCopy.fargoInfoButton, role: .cancel) { }
        } message: {
            Text(DashboardCopy.fargoInfoMessage)
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
        DashboardRecentFormSection(
            recentMatches: Array(filteredSessions.filter { $0.type == "match" }.sorted(by: Session.newestFirst).prefix(10))
        )
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
                    let fallbackDate = points.first?.0 ?? Date()
                    let domainStart = series.dates.first ?? fallbackDate
                    let domainEnd = series.dates.last ?? fallbackDate
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
        let layoutLabels = DashboardCopy.layoutLabels
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
        DashboardActivitySection(sessions: store.sessions, activeDays: activityActiveDays)
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
        let pos = rolling(recent.map { perRack(\.positionTrackingCount, $0) })
        let saf = rolling(recent.map { perRack(\.safetyCount, $0) })
        let pattern = rolling(recent.map { perRack(\.patternMistakeCount, $0) })

        return recent.enumerated().flatMap { i, session in
            let m = miss[i]; let p = pos[i]; let s = saf[i]; let pat = pattern[i]
            return [
                ErrorStackPoint(id: "\(session.id)-m", sessionIndex: i, bottom: 0, top: m, kind: .miss),
                ErrorStackPoint(id: "\(session.id)-p", sessionIndex: i, bottom: m, top: m + p, kind: .position),
                ErrorStackPoint(id: "\(session.id)-s", sessionIndex: i, bottom: m + p, top: m + p + s, kind: .safety),
                ErrorStackPoint(id: "\(session.id)-pat", sessionIndex: i, bottom: m + p + s, top: m + p + s + pat, kind: .pattern)
            ]
        }
    }

    private func presentExportSheet() {
        do {
            let data = try store.exportBackup(
                goals: goalsStore.goals,
                opponents: opponentStore.profiles,
                playerProfile: profileStore.profile,
                social: socialProfileStore.localBackup(),
                activeSession: logStore.activeSnapshot
            )
            importExportState.exportDocument = JSONDocument(data: data)
            importExportState.isShowingExporter = true
        } catch {
            importExportState.exportErrorMessage = error.localizedDescription
            importExportState.isShowingExportError = true
        }
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
            Text(LocalizedStringKey(label))
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

private struct DashboardRecentFormSection: View {
    let recentMatches: [Session]

    var body: some View {
        let wins = recentMatches.filter { $0.wins > $0.losses }.count
        let draws = recentMatches.filter { $0.wins == $0.losses }.count
        let losses = recentMatches.filter { $0.losses > $0.wins }.count
        let copy = DashboardCopy.recentFormPresentation(
            recentCount: recentMatches.count,
            wins: wins,
            draws: draws,
            losses: losses
        )

        SectionCard(title: "Recent form") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(copy.subtitle)
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                    Spacer(minLength: 8)
                    Text(copy.recordText)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(recentMatches.isEmpty ? Theme.muted : Theme.text2)
                }

                if let emptyStateMessage = copy.emptyStateMessage {
                    Text(emptyStateMessage)
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    RecentFormVisual(sessions: Array(recentMatches.reversed()))
                    RecentOutcomeMixBar(wins: wins, draws: draws, losses: losses)
                    HStack {
                        Text(copy.legendTitle)
                            .font(.caption2)
                            .foregroundColor(Theme.text2)
                        Spacer(minLength: 8)
                        Text(copy.legendValue)
                            .font(.caption2.weight(.medium))
                            .foregroundColor(Theme.text2)
                    }
                }
            }
        }
    }
}

private struct DashboardActivitySection: View {
    let sessions: [Session]
    let activeDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Training activity")
                    .font(.subheadline)
                    .foregroundColor(Theme.text2)
                Spacer(minLength: 0)
                Text(DashboardCopy.activeDays(activeDays))
                    .font(.caption2)
                    .foregroundColor(Theme.muted)
            }
            ActivityHeatmapView(sessions: sessions)
        }
        .padding(14)
        .background(Theme.panel)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
    }
}
