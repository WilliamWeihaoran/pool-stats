import Foundation

enum GoalWindowUnit: String, CaseIterable, Codable, Identifiable {
    case racks
    case sessions
    case days
    case weeks

    var id: String { rawValue }

    var label: String {
        switch self {
        case .racks: return NSLocalizedString("Racks", comment: "")
        case .sessions: return NSLocalizedString("Sessions", comment: "")
        case .days: return NSLocalizedString("Days", comment: "")
        case .weeks: return NSLocalizedString("Weeks", comment: "")
        }
    }

    var shortLabel: String {
        switch self {
        case .racks: return NSLocalizedString("racks", comment: "")
        case .sessions: return NSLocalizedString("sessions", comment: "")
        case .days: return NSLocalizedString("days", comment: "")
        case .weeks: return NSLocalizedString("weeks", comment: "")
        }
    }
}

struct GoalRollingWindow: Codable, Hashable {
    var amount: Int
    var unit: GoalWindowUnit

    var label: String {
        AppLanguageRuntime.localizedFormat("%lld rolling %@", amount, unit.shortLabel)
    }
}

enum GoalWindow: Codable, Hashable, Identifiable {
    case rolling(GoalRollingWindow)
    case dueDate(Date)

    enum CodingKeys: String, CodingKey {
        case kind
        case amount
        case unit
        case date
    }

    enum Kind: String, Codable {
        case rolling
        case dueDate
    }

    var id: String {
        switch self {
        case .rolling(let window):
            return "rolling-\(window.amount)-\(window.unit.rawValue)"
        case .dueDate(let date):
            return "due-\(Int(date.timeIntervalSince1970))"
        }
    }

    var label: String {
        switch self {
        case .rolling(let window):
            return window.label
        case .dueDate(let date):
            return String(format: NSLocalizedString("Due %@", comment: ""), AppFormatters.sessionDate(date))
        }
    }

    var modeLabel: String {
        switch self {
        case .rolling:
            return NSLocalizedString("Rolling", comment: "")
        case .dueDate:
            return NSLocalizedString("Due date", comment: "")
        }
    }

    func apply(to sessions: [Session], createdAt: Date = .distantPast, now: Date = Date()) -> [Session] {
        let sorted = sessions.sorted { $0.ts > $1.ts }
        switch self {
        case .rolling(let window):
            switch window.unit {
            case .sessions:
                return Array(sorted.prefix(max(window.amount, 0)))
            case .racks:
                if window.amount <= 0 { return sorted }
                var count = 0
                var result: [Session] = []
                for session in sorted {
                    result.append(session)
                    count += session.racks.count
                    if count >= window.amount { break }
                }
                return result
            case .days:
                let cutoff = Calendar.current.date(byAdding: .day, value: -window.amount, to: now) ?? Date.distantPast
                return sorted.filter { $0.ts >= cutoff }
            case .weeks:
                let cutoff = Calendar.current.date(byAdding: .day, value: -(7 * window.amount), to: now) ?? Date.distantPast
                return sorted.filter { $0.ts >= cutoff }
            }
        case .dueDate(let date):
            let start = createdAt
            let end = min(date, now)
            return sorted.filter { $0.ts >= start && $0.ts <= end }
        }
    }

    init(from decoder: Decoder) throws {
        if let legacy = try? decoder.singleValueContainer().decode(String.self) {
            self = Self.legacy(from: legacy)
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .rolling:
            let amount = try container.decode(Int.self, forKey: .amount)
            let unit = try container.decode(GoalWindowUnit.self, forKey: .unit)
            self = .rolling(GoalRollingWindow(amount: amount, unit: unit))
        case .dueDate:
            let date = try container.decode(Date.self, forKey: .date)
            self = .dueDate(date)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .rolling(let window):
            try container.encode(Kind.rolling, forKey: .kind)
            try container.encode(window.amount, forKey: .amount)
            try container.encode(window.unit, forKey: .unit)
        case .dueDate(let date):
            try container.encode(Kind.dueDate, forKey: .kind)
            try container.encode(date, forKey: .date)
        }
    }

    private static func legacy(from raw: String) -> GoalWindow {
        switch raw {
        case "allTime":
            return .rolling(.init(amount: 0, unit: .sessions))
        case "last10Sessions":
            return .rolling(.init(amount: 10, unit: .sessions))
        case "last30Sessions":
            return .rolling(.init(amount: 30, unit: .sessions))
        case "last90Days":
            return .rolling(.init(amount: 90, unit: .days))
        default:
            return .rolling(.init(amount: 30, unit: .sessions))
        }
    }
}
