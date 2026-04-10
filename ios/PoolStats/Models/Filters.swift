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
        case .today: return "Today"
        case .week: return "Week"
        case .month: return "Month"
        case .threeMonths: return "3mo"
        case .year: return "Year"
        case .all: return "All"
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
        case .all: return "All"
        case .match: return "Match"
        case .practice: return "Practice"
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
        case .all: return "All"
        case .eightBall: return "8-ball"
        case .nineBall: return "9-ball"
        case .practice: return "Practice"
        }
    }
}

enum OutcomeTarget: String, CaseIterable, Identifiable {
    case match
    case rack

    var id: String { rawValue }

    var label: String {
        switch self {
        case .match: return "Match"
        case .rack: return "Rack"
        }
    }
}
