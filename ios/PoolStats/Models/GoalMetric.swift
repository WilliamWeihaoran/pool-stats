import Foundation

enum GoalDirection: String, Codable, CaseIterable {
    case improve
    case reduce
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
    case foulErrors
    case averagePerformance

    var id: String { rawValue }

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
        case .foulErrors: return "Foul errors"
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
        case .missErrors, .positionalErrors, .safetyErrors, .foulErrors:
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
        case .runouts, .breakAndRuns, .missErrors, .positionalErrors, .safetyErrors, .foulErrors:
            return ""
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
            return Double(sessions.flatMap(\.racks).reduce(0) { $0 + $1.positionalCount })
        case .safetyErrors:
            return Double(sessions.flatMap(\.racks).reduce(0) { $0 + $1.safetyCount })
        case .foulErrors:
            return Double(sessions.flatMap(\.racks).reduce(0) { $0 + $1.foulCount })
        case .averagePerformance:
            let ratings = sessions.compactMap { $0.performanceRating }
            guard !ratings.isEmpty else { return 0 }
            return Double(ratings.reduce(0, +)) / Double(ratings.count)
        }
    }

    func format(_ value: Double) -> String {
        switch self {
        case .conversionRate, .matchWinRate, .rackWinRate:
            return "\(Int(round(value)))%"
        case .averagePerformance:
            return String(format: "%.1f/10", value)
        case .runouts, .breakAndRuns, .missErrors, .positionalErrors, .safetyErrors, .foulErrors:
            return "\(Int(round(value)))"
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
