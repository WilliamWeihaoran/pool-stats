import Foundation

enum GoalDirection: String, Codable, CaseIterable {
    case improve
    case reduce
}

enum GoalValueStyle: String, Codable, CaseIterable, Identifiable {
    case average
    case cumulative

    var id: String { rawValue }

    var label: String {
        switch self {
        case .average: return "Average"
        case .cumulative: return "Cumulative"
        }
    }
}

enum GoalAverageBasis: String, Codable, CaseIterable, Identifiable {
    case racks
    case sessions

    var id: String { rawValue }

    var label: String {
        switch self {
        case .racks: return "Per rack"
        case .sessions: return "Per session"
        }
    }

    var unitLabel: String {
        switch self {
        case .racks: return "rack"
        case .sessions: return "session"
        }
    }
}

enum GoalSessionScope: String, Codable, CaseIterable, Identifiable {
    case all
    case match
    case practice

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All sessions"
        case .match: return "Match only"
        case .practice: return "Practice only"
        }
    }

    var shortLabel: String {
        switch self {
        case .all: return "All"
        case .match: return "Match"
        case .practice: return "Practice"
        }
    }

    func apply(to sessions: [Session]) -> [Session] {
        switch self {
        case .all:
            return sessions
        case .match:
            return sessions.filter { !$0.isPractice }
        case .practice:
            return sessions.filter(\.isPractice)
        }
    }
}

enum GoalMetric: String, CaseIterable, Codable, Identifiable {
    case conversionRate
    case matchWinRate
    case rackWinRate
    case runouts
    case breakAndRuns
    case missErrors
    case positionalErrors
    case safetyErrors
    case patternErrors
    case foulErrors
    case averagePerformance

    var id: String { rawValue }

    static var allCases: [GoalMetric] {
        [
            .conversionRate,
            .matchWinRate,
            .rackWinRate,
            .runouts,
            .breakAndRuns,
            .missErrors,
            .positionalErrors,
            .safetyErrors,
            .patternErrors,
            .averagePerformance
        ]
    }

    var label: String {
        switch self {
        case .conversionRate: return "Conversion rate"
        case .matchWinRate: return "Match win rate"
        case .rackWinRate: return "Rack win rate"
        case .runouts: return "Runouts"
        case .breakAndRuns: return "Break & runs"
        case .missErrors: return "Miss errors"
        case .positionalErrors: return "Positional errors"
        case .safetyErrors: return "Safety errors"
        case .patternErrors: return "Pattern errors"
        case .foulErrors: return "Foul errors (legacy)"
        case .averagePerformance: return "Performance rating"
        }
    }

    var groupLabel: String {
        isLowerBetter ? "Trim" : "Grow"
    }

    var direction: GoalDirection {
        isLowerBetter ? .reduce : .improve
    }

    var isLowerBetter: Bool {
        switch self {
        case .missErrors, .positionalErrors, .safetyErrors, .patternErrors, .foulErrors:
            return true
        default:
            return false
        }
    }

    var unit: String {
        switch self {
        case .conversionRate, .matchWinRate, .rackWinRate:
            return "%"
        case .averagePerformance:
            return "/10"
        case .runouts, .breakAndRuns, .missErrors, .positionalErrors, .safetyErrors, .patternErrors, .foulErrors:
            return ""
        }
    }

    var supportsValueStyle: Bool {
        switch self {
        case .runouts, .breakAndRuns, .missErrors, .positionalErrors, .safetyErrors, .patternErrors, .foulErrors:
            return true
        default:
            return false
        }
    }

    var defaultAverageBasis: GoalAverageBasis {
        switch self {
        case .runouts, .breakAndRuns:
            return .sessions
        default:
            return .racks
        }
    }

    var defaultValueStyle: GoalValueStyle {
        switch self {
        case .runouts, .breakAndRuns:
            return .cumulative
        case .missErrors, .positionalErrors, .safetyErrors, .patternErrors, .foulErrors:
            return .average
        default:
            return .cumulative
        }
    }

    func value(from sessions: [Session]) -> Double {
        switch self {
        case .conversionRate:
            let racks = sessions.flatMap(\.racks)
            let open = racks.filter { $0.layout == "open" }
            guard !open.isEmpty else { return 0 }
            let converted = open.filter { $0.outcome == "runout" }.count
            return Double(converted) / Double(open.count) * 100
        case .matchWinRate:
            let matches = sessions.filter { $0.type == "match" }
            guard !matches.isEmpty else { return 0 }
            let wins = matches.filter { $0.wins > $0.racks.count / 2 }.count
            return Double(wins) / Double(matches.count) * 100
        case .rackWinRate:
            let racks = sessions.flatMap(\.racks)
            guard !racks.isEmpty else { return 0 }
            let wins = racks.filter { $0.result == "won" }.count
            return Double(wins) / Double(racks.count) * 100
        case .runouts:
            return Double(sessions.flatMap(\.racks).filter { $0.outcome == "runout" }.count)
        case .breakAndRuns:
            return Double(sessions.flatMap(\.racks).filter { $0.breakAndRun }.count)
        case .missErrors:
            return Double(sessions.flatMap(\.racks).reduce(0) { $0 + $1.missCount })
        case .positionalErrors:
            return Double(sessions.flatMap(\.racks).reduce(0) { $0 + $1.positionTrackingCount })
        case .safetyErrors:
            return Double(sessions.flatMap(\.racks).reduce(0) { $0 + $1.safetyCount })
        case .patternErrors:
            return Double(sessions.flatMap(\.racks).reduce(0) { $0 + $1.patternMistakeCount })
        case .foulErrors:
            return Double(sessions.flatMap(\.racks).reduce(0) { $0 + $1.foulCount })
        case .averagePerformance:
            let ratings = sessions.compactMap { $0.performanceRating }
            guard !ratings.isEmpty else { return 0 }
            return Double(ratings.reduce(0, +)) / Double(ratings.count)
        }
    }

    func value(from sessions: [Session], style: GoalValueStyle, basis: GoalAverageBasis? = nil) -> Double {
        guard supportsValueStyle else { return value(from: sessions) }
        let racks = sessions.flatMap(\.racks)
        let total: Double
        switch self {
        case .runouts:
            total = Double(racks.filter { $0.outcome == "runout" }.count)
        case .breakAndRuns:
            total = Double(racks.filter { $0.breakAndRun }.count)
        case .missErrors:
            total = Double(racks.reduce(0) { $0 + $1.missCount })
        case .positionalErrors:
            total = Double(racks.reduce(0) { $0 + $1.positionTrackingCount })
        case .safetyErrors:
            total = Double(racks.reduce(0) { $0 + $1.safetyCount })
        case .patternErrors:
            total = Double(racks.reduce(0) { $0 + $1.patternMistakeCount })
        case .foulErrors:
            total = Double(racks.reduce(0) { $0 + $1.foulCount })
        default:
            return value(from: sessions)
        }

        guard style == .average else { return total }
        let basis = basis ?? defaultAverageBasis
        let denominator: Double
        switch basis {
        case .racks:
            denominator = Double(racks.count)
        case .sessions:
            denominator = Double(sessions.count)
        }
        guard denominator > 0 else { return 0 }
        return total / denominator
    }

    func format(_ value: Double, style: GoalValueStyle = .cumulative, basis: GoalAverageBasis? = nil) -> String {
        switch self {
        case .conversionRate, .matchWinRate, .rackWinRate:
            return "\(Int(round(value)))%"
        case .averagePerformance:
            return String(format: "%.1f/10", value)
        case .runouts, .breakAndRuns, .missErrors, .positionalErrors, .safetyErrors, .patternErrors, .foulErrors:
            if style == .average {
                return String(format: "%.1f", value)
            }
            return "\(Int(round(value)))"
        }
    }

    func scopeLabel(style: GoalValueStyle, basis: GoalAverageBasis?) -> String {
        guard supportsValueStyle else { return "" }
        switch style {
        case .cumulative:
            return "Cumulative"
        case .average:
            let basis = basis ?? defaultAverageBasis
            return "Average per \(basis.unitLabel)"
        }
    }

    func goalSummary(target: Double, style: GoalValueStyle, basis: GoalAverageBasis? = nil) -> String {
        let formatted = format(target, style: style, basis: basis)
        switch self {
        case .conversionRate, .matchWinRate, .rackWinRate:
            return "\(label) \(isLowerBetter ? "under" : "above") \(formatted)"
        case .averagePerformance:
            return "\(label) \(isLowerBetter ? "under" : "above") \(formatted)"
        case .runouts, .breakAndRuns, .missErrors, .positionalErrors, .safetyErrors, .patternErrors, .foulErrors:
            if style == .average {
                let basis = basis ?? defaultAverageBasis
                return "\(isLowerBetter ? "Keep" : "Average") \(label.lowercased()) \(isLowerBetter ? "under" : "at") \(formatted) per \(basis.unitLabel)"
            }
            return isLowerBetter ? "Keep \(label.lowercased()) under \(formatted)" : "Record \(formatted) \(label.lowercased())"
        }
    }

    func suggestedResetTarget(from target: Double) -> Double {
        switch self {
        case .conversionRate, .matchWinRate, .rackWinRate:
            let step = max(1, round(target * 0.05))
            return isLowerBetter ? max(0, target - step) : min(100, target + step)
        case .averagePerformance:
            let step = 0.5
            return isLowerBetter ? max(0, target - step) : target + step
        default:
            let step = max(1, round(target * 0.1))
            return isLowerBetter ? max(0, target - step) : target + step
        }
    }
}

extension GoalWindow {
    func plainEnglishSuffix() -> String {
        switch self {
        case .rolling(let rolling):
            let amountText = rolling.amount == 1 ? "1" : "\(rolling.amount)"
            return "over \(amountText) rolling \(rolling.unit.shortLabel)"
        case .dueDate(let date):
            return "by \(AppFormatters.sessionDate(date))"
        }
    }
}

extension Goal {
    var plainEnglishSummary: String {
        "\(metric.goalSummary(target: target, style: valueStyle, basis: averageBasis)) \(window.plainEnglishSuffix()) (\(sessionScope.shortLabel.lowercased()))"
    }

    func currentValue(from sessions: [Session]) -> Double {
        let scoped = sessionScope.apply(to: sessions)
        let filtered = window.apply(to: scoped, createdAt: createdAt)
        return metric.value(from: filtered, style: valueStyle, basis: averageBasis)
    }
}
