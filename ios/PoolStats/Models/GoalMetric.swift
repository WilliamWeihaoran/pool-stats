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
        case .average: return NSLocalizedString("Average", comment: "")
        case .cumulative: return NSLocalizedString("Cumulative", comment: "")
        }
    }
}

enum GoalAverageBasis: String, Codable, CaseIterable, Identifiable {
    case racks
    case sessions

    var id: String { rawValue }

    var label: String {
        switch self {
        case .racks: return NSLocalizedString("Per rack", comment: "")
        case .sessions: return NSLocalizedString("Per session", comment: "")
        }
    }

    var unitLabel: String {
        switch self {
        case .racks: return NSLocalizedString("rack", comment: "")
        case .sessions: return NSLocalizedString("session", comment: "")
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
        case .all: return NSLocalizedString("All sessions", comment: "")
        case .match: return NSLocalizedString("Match only", comment: "")
        case .practice: return NSLocalizedString("Practice only", comment: "")
        }
    }

    var shortLabel: String {
        switch self {
        case .all: return NSLocalizedString("All", comment: "")
        case .match: return NSLocalizedString("Match", comment: "")
        case .practice: return NSLocalizedString("Practice", comment: "")
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
        case .conversionRate: return NSLocalizedString("Conversion rate", comment: "")
        case .matchWinRate: return NSLocalizedString("Match win rate", comment: "")
        case .rackWinRate: return NSLocalizedString("Rack win rate", comment: "")
        case .runouts: return NSLocalizedString("Runouts", comment: "")
        case .breakAndRuns: return NSLocalizedString("Break & runs", comment: "")
        case .missErrors: return NSLocalizedString("Miss errors", comment: "")
        case .positionalErrors: return NSLocalizedString("Positional errors", comment: "")
        case .safetyErrors: return NSLocalizedString("Safety errors", comment: "")
        case .patternErrors: return NSLocalizedString("Pattern errors", comment: "")
        case .foulErrors: return NSLocalizedString("Foul errors (legacy)", comment: "")
        case .averagePerformance: return NSLocalizedString("Performance rating", comment: "")
        }
    }

    var groupLabel: String {
        isLowerBetter ? NSLocalizedString("Trim", comment: "") : NSLocalizedString("Grow", comment: "")
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

    var updatesFromInProgressSession: Bool {
        switch self {
        case .conversionRate, .rackWinRate, .runouts, .breakAndRuns, .missErrors, .positionalErrors, .safetyErrors, .patternErrors, .foulErrors:
            return true
        case .matchWinRate, .averagePerformance:
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

    func hasProgressData(from sessions: [Session], style: GoalValueStyle, basis: GoalAverageBasis? = nil) -> Bool {
        let racks = sessions.flatMap(\.racks)
        switch self {
        case .conversionRate:
            return racks.contains { $0.layout == "open" }
        case .matchWinRate:
            return sessions.contains { $0.type == "match" }
        case .rackWinRate:
            return !racks.isEmpty
        case .runouts, .breakAndRuns, .missErrors, .positionalErrors, .safetyErrors, .patternErrors, .foulErrors:
            if style == .average, (basis ?? defaultAverageBasis) == .sessions {
                return !sessions.isEmpty
            }
            return !racks.isEmpty
        case .averagePerformance:
            return sessions.contains { $0.performanceRating != nil }
        }
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
            return NSLocalizedString("Cumulative", comment: "")
        case .average:
            let basis = basis ?? defaultAverageBasis
            return String(format: NSLocalizedString("Average per %@", comment: ""), basis.unitLabel)
        }
    }

    func goalSummary(target: Double, style: GoalValueStyle, basis: GoalAverageBasis? = nil) -> String {
        let formatted = format(target, style: style, basis: basis)
        switch self {
        case .conversionRate, .matchWinRate, .rackWinRate:
            let comparator = isLowerBetter ? NSLocalizedString("under", comment: "") : NSLocalizedString("above", comment: "")
            return "\(label) \(comparator) \(formatted)"
        case .averagePerformance:
            let comparator = isLowerBetter ? NSLocalizedString("under", comment: "") : NSLocalizedString("above", comment: "")
            return "\(label) \(comparator) \(formatted)"
        case .runouts, .breakAndRuns, .missErrors, .positionalErrors, .safetyErrors, .patternErrors, .foulErrors:
            if style == .average {
                let basis = basis ?? defaultAverageBasis
                let prefix = isLowerBetter ? NSLocalizedString("Keep", comment: "") : NSLocalizedString("Average", comment: "")
                let comparator = isLowerBetter ? NSLocalizedString("under", comment: "") : NSLocalizedString("at", comment: "")
                return AppLanguageRuntime.localizedFormat(
                    "%@ %@ %@ %@ per %@",
                    prefix,
                    label.lowercased(with: AppLanguageRuntime.locale),
                    comparator,
                    formatted,
                    basis.unitLabel
                )
            }
            if isLowerBetter {
                return AppLanguageRuntime.localizedFormat(
                    "Keep %@ under %@",
                    label.lowercased(with: AppLanguageRuntime.locale),
                    formatted
                )
            }
            return AppLanguageRuntime.localizedFormat(
                "Record %@ %@",
                formatted,
                label.lowercased(with: AppLanguageRuntime.locale)
            )
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
            return AppLanguageRuntime.localizedFormat("over %lld rolling %@", rolling.amount, rolling.unit.shortLabel)
        case .dueDate(let date):
            return String(format: NSLocalizedString("by %@", comment: ""), AppFormatters.sessionDate(date))
        }
    }
}

extension Goal {
    var plainEnglishSummary: String {
        String(
            format: NSLocalizedString("%@ %@ (%@)", comment: ""),
            metric.goalSummary(target: target, style: valueStyle, basis: averageBasis),
            window.plainEnglishSuffix(),
            sessionScope.shortLabel.lowercased(with: AppLanguageRuntime.locale)
        )
    }

    func currentValue(from sessions: [Session]) -> Double {
        let scoped = sessionScope.apply(to: sessions)
        let filtered = window.apply(to: scoped, createdAt: createdAt)
        return metric.value(from: filtered, style: valueStyle, basis: averageBasis)
    }

    func hasProgressData(from sessions: [Session]) -> Bool {
        let scoped = sessionScope.apply(to: sessions)
        let filtered = window.apply(to: scoped, createdAt: createdAt)
        return metric.hasProgressData(from: filtered, style: valueStyle, basis: averageBasis)
    }

    func isComplete(from sessions: [Session]) -> Bool {
        guard completedAt == nil, hasProgressData(from: sessions) else { return false }
        let current = currentValue(from: sessions)
        return metric.isLowerBetter ? current <= target : current >= target
    }

    var canAutoCompleteFromStats: Bool {
        completedAt == nil
            && !isArchived
            && !metric.isLowerBetter
            && metric.supportsValueStyle
            && valueStyle == .cumulative
    }
}
