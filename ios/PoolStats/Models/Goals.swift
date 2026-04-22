import Foundation

enum GoalWindowUnit: String, CaseIterable, Codable, Identifiable {
    case racks
    case sessions
    case days
    case weeks

    var id: String { rawValue }

    var label: String {
        switch self {
        case .racks: return "Racks"
        case .sessions: return "Sessions"
        case .days: return "Days"
        case .weeks: return "Weeks"
        }
    }

    var shortLabel: String {
        switch self {
        case .racks: return "racks"
        case .sessions: return "sessions"
        case .days: return "days"
        case .weeks: return "weeks"
        }
    }
}

struct GoalRollingWindow: Codable, Hashable {
    var amount: Int
    var unit: GoalWindowUnit

    var label: String {
        let amountText = amount == 1 ? "1" : "\(amount)"
        return "\(amountText) rolling \(unit.shortLabel)"
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
            return "Due \(AppFormatters.sessionDate(date))"
        }
    }

    var modeLabel: String {
        switch self {
        case .rolling:
            return "Rolling"
        case .dueDate:
            return "Due date"
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

enum GoalDirection: String, Codable, CaseIterable {
    case improve
    case reduce
}

struct Goal: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var metric: GoalMetric
    var target: Double
    var window: GoalWindow
    var createdAt: Date = Date()
    var notes: String = ""
    var isArchived: Bool = false
    var completedAt: Date? = nil
}

@MainActor
final class GoalsStore: ObservableObject {
    @Published var goals: [Goal] = []

    private let seedKey = "poolstats.goals.seeded"
    private let localURL: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("PoolStats", isDirectory: true)
        localURL = dir.appendingPathComponent("goals.json")
        loadLocal()
        seedIfNeeded()
    }

    func add(_ goal: Goal) {
        goals.insert(goal, at: 0)
        saveLocal()
    }

    func update(_ goal: Goal) {
        if let idx = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[idx] = goal
            saveLocal()
        }
    }

    func delete(_ goal: Goal) {
        goals.removeAll { $0.id == goal.id }
        saveLocal()
    }

    func complete(_ goal: Goal) {
        guard let idx = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        goals[idx].completedAt = Date()
        goals[idx].isArchived = true
        saveLocal()
    }

    func toggleArchive(_ goal: Goal) {
        guard let idx = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        goals[idx].isArchived.toggle()
        saveLocal()
    }

    func resetToSamples() {
        goals = Self.sampleGoals()
        UserDefaults.standard.set(true, forKey: seedKey)
        saveLocal()
    }

    private func seedIfNeeded() {
        guard goals.isEmpty else { return }
        if UserDefaults.standard.bool(forKey: seedKey) { return }
        goals = Self.sampleGoals()
        UserDefaults.standard.set(true, forKey: seedKey)
        saveLocal()
    }

    private func loadLocal() {
        guard let data = try? Data(contentsOf: localURL) else { return }
        if let loaded = try? JSONDecoder().decode([Goal].self, from: data) {
            goals = loaded
        }
    }

    private func saveLocal() {
        guard let data = try? JSONEncoder.pretty.encode(goals) else { return }
        let dir = localURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: localURL, options: .atomic)
    }

    private static func sampleGoals() -> [Goal] {
        [
            Goal(title: "Open layouts to 55%", metric: .conversionRate, target: 55, window: .rolling(.init(amount: 30, unit: .sessions))),
            Goal(title: "Match win rate above 70%", metric: .matchWinRate, target: 70, window: .rolling(.init(amount: 10, unit: .sessions))),
            Goal(title: "Keep positional errors under 6", metric: .positionalErrors, target: 6, window: .rolling(.init(amount: 100, unit: .racks))),
            Goal(title: "Record 100 runouts by year end", metric: .runouts, target: 100, window: .dueDate(Calendar.current.date(from: DateComponents(year: Calendar.current.component(.year, from: Date()), month: 12, day: 31)) ?? Date())),
            Goal(title: "Break-and-run 2+ times a week", metric: .breakAndRuns, target: 2, window: .rolling(.init(amount: 1, unit: .weeks))),
            Goal(title: "Average performance 7.0+", metric: .averagePerformance, target: 7.0, window: .rolling(.init(amount: 10, unit: .sessions))),
            Goal(title: "Keep miss errors under 8", metric: .missErrors, target: 8, window: .rolling(.init(amount: 30, unit: .sessions)))
        ]
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
