import SwiftUI
import Charts

struct RecentFormVisual: View {
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

struct RecentOutcomeMixBar: View {
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

struct ErrorStackPoint: Identifiable {
    let id: String
    let sessionIndex: Int
    let bottom: Double
    let top: Double
    let kind: ErrorTrendKind
}

enum ErrorTrendKind: String, CaseIterable, Identifiable {
    case miss
    case position
    case safety
    case pattern

    var id: String { rawValue }

    var localizedLabel: String {
        switch self {
        case .miss:
            return NSLocalizedString("Miss", comment: "")
        case .position:
            return NSLocalizedString("Position", comment: "")
        case .safety:
            return NSLocalizedString("Safety", comment: "")
        case .pattern:
            return NSLocalizedString("Pattern", comment: "")
        }
    }

    var color: Color {
        switch self {
        case .miss:
            return Theme.red
        case .position:
            return Theme.amber
        case .safety:
            return Theme.teal
        case .pattern:
            return Theme.purple
        }
    }
}

struct ErrorTrendChart: View {
    let data: [ErrorStackPoint]
    let chartHeight: CGFloat

    var body: some View {
        if data.isEmpty {
            Text("Need 3+ sessions to show trend")
                .font(.caption)
                .foregroundColor(Theme.muted)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                chartBody
                ErrorTrendLegend()
                Text("Errors per rack · 5-session rolling avg")
                    .font(.caption2)
                    .foregroundColor(Theme.muted)
            }
        }
    }

    private var chartBody: some View {
        Chart(data) { point in
            AreaMark(
                x: .value("Session", point.sessionIndex),
                yStart: .value("Bottom", point.bottom),
                yEnd: .value("Top", point.top)
            )
            .foregroundStyle(by: .value("ErrorKind", point.kind.rawValue))
            .interpolationMethod(.monotone)
        }
        .chartForegroundStyleScale(
            domain: ErrorTrendKind.allCases.map(\.rawValue),
            range: ErrorTrendKind.allCases.map(\.color)
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
                        Text(AppLanguageRuntime.format("%.1f", val)).font(.caption2)
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .frame(height: chartHeight)
    }
}

private struct ErrorTrendLegend: View {
    var body: some View {
        HStack(spacing: 12) {
            ForEach(ErrorTrendKind.allCases) { kind in
                HStack(spacing: 5) {
                    Circle()
                        .fill(kind.color)
                        .frame(width: 7, height: 7)
                    Text(kind.localizedLabel)
                        .font(.caption2)
                        .foregroundColor(Theme.muted)
                }
            }
        }
    }
}

struct ActivityHeatmapView: View {
    let sessions: [Session]

    private let cellSpacing: CGFloat = 2
    private let weeks = 18
    private let days = 7

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

    private var monthLabels: [(text: String, col: Int)] {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.locale = AppLanguageRuntime.locale
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
}
