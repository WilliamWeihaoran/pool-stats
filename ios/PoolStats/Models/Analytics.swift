import Foundation

enum FargoFactorKind: String, CaseIterable, Identifiable {
    case potting
    case position
    case pattern
    case runout
    case overall

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .potting:
            return NSLocalizedString("Potting", comment: "")
        case .position:
            return NSLocalizedString("Position", comment: "")
        case .pattern:
            return NSLocalizedString("Pattern", comment: "")
        case .runout:
            return NSLocalizedString("Runout", comment: "")
        case .overall:
            return NSLocalizedString("Overall", comment: "")
        }
    }
}

struct MetricItem: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

struct WLItem: Identifiable {
    let id = UUID()
    let label: String
    let won: Double
    let lost: Double
}

struct TrendSeries {
    let dates: [Date]
    let labels: [String]
    let match: [Double?]
    let rack: [Double?]
}

struct FargoFactor: Identifiable {
    let id = UUID()
    let kind: FargoFactorKind
    let scoreValue: Int
    let valueText: String
    let weightText: String
    let contribution: Int

    var name: String { kind.localizedName }
}

struct FargoResult {
    let estimatedScore: Int
    let rangeText: String
    let factors: [FargoFactor]
}

struct InsightsResult {
    let breakCards: [(String, Int?)]
    let layoutRates: [Int?]
}

struct Analytics {
    static func filteredSessions(_ sessions: [Session], timeFilter: TimeFilter, mode: ModeFilter) -> [Session] {
        let base: [Session]
        if timeFilter == .all {
            base = sessions
        } else {
            let cutoff = Date().addingTimeInterval(TimeInterval(-timeFilter.rawValue * 86_400))
            base = sessions.filter { $0.ts >= cutoff }
        }
        switch mode {
        case .all:
            return base
        case .match:
            return base.filter { $0.type == "match" }
        case .practice:
            return base.filter { $0.type == "practice" }
        }
    }

    static func filteredRacks(_ sessions: [Session], game: String? = nil) -> [Rack] {
        sessions
            .filter { game == nil || $0.game == game }
            .flatMap { $0.racks }
    }

    static func matchOnly(_ sessions: [Session]) -> [Session] {
        sessions.filter { $0.type == "match" }
    }

    static func matchRacks(_ sessions: [Session], game: String? = nil) -> [Rack] {
        sessions
            .filter { $0.type == "match" && (game == nil || $0.game == game) }
            .flatMap { $0.racks }
    }
}
