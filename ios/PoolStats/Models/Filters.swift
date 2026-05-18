import Foundation

enum TimeFilter: Int, CaseIterable, Identifiable {
    case today = 1
    case week = 7
    case month = 30
    case threeMonths = 90
    case year = 365
    case all = 0

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .today: return NSLocalizedString("Today", comment: "")
        case .week: return NSLocalizedString("Week", comment: "")
        case .month: return NSLocalizedString("Month", comment: "")
        case .threeMonths: return "3mo"
        case .year: return NSLocalizedString("Year", comment: "")
        case .all: return NSLocalizedString("All", comment: "")
        }
    }
}

enum ModeFilter: String, CaseIterable, Identifiable {
    case all
    case match
    case practice

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return NSLocalizedString("All", comment: "")
        case .match: return NSLocalizedString("Match", comment: "")
        case .practice: return NSLocalizedString("Practice", comment: "")
        }
    }
}

enum GameFilter: String, CaseIterable, Identifiable {
    case all
    case eightBall = "8ball"
    case nineBall = "9ball"
    case practice

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return NSLocalizedString("All", comment: "")
        case .eightBall: return "8-ball"
        case .nineBall: return "9-ball"
        case .practice: return NSLocalizedString("Practice", comment: "")
        }
    }
}

enum OutcomeTarget: String, CaseIterable, Identifiable {
    case match
    case rack

    var id: String { rawValue }

    var label: String {
        switch self {
        case .match: return NSLocalizedString("Match", comment: "")
        case .rack: return NSLocalizedString("Rack", comment: "")
        }
    }
}
