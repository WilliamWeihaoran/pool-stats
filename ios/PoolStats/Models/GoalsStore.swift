import Foundation

struct Goal: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var metric: GoalMetric
    var target: Double
    var window: GoalWindow
    var valueStyle: GoalValueStyle = .cumulative
    var averageBasis: GoalAverageBasis = .racks
    var sessionScope: GoalSessionScope = .all
    var createdAt: Date = Date()
    var notes: String = ""
    var isArchived: Bool = false
    var completedAt: Date? = nil
    var starterGenerated: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, title, metric, target, window, valueStyle, averageBasis, sessionScope, createdAt, notes, isArchived, completedAt, starterGenerated
    }

    init(id: UUID = UUID(),
         title: String,
         metric: GoalMetric,
         target: Double,
         window: GoalWindow,
         valueStyle: GoalValueStyle = .cumulative,
         averageBasis: GoalAverageBasis = .racks,
         sessionScope: GoalSessionScope = .all,
         createdAt: Date = Date(),
         notes: String = "",
         isArchived: Bool = false,
         completedAt: Date? = nil,
         starterGenerated: Bool = false) {
        self.id = id
        self.title = title
        self.metric = metric
        self.target = target
        self.window = window
        self.valueStyle = metric.supportsValueStyle ? valueStyle : .cumulative
        self.averageBasis = metric.supportsValueStyle ? averageBasis : metric.defaultAverageBasis
        self.sessionScope = sessionScope
        self.createdAt = createdAt
        self.notes = notes
        self.isArchived = isArchived
        self.completedAt = completedAt
        self.starterGenerated = starterGenerated
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        metric = try container.decode(GoalMetric.self, forKey: .metric)
        target = try container.decode(Double.self, forKey: .target)
        window = try container.decode(GoalWindow.self, forKey: .window)
        let decodedStyle = try container.decodeIfPresent(GoalValueStyle.self, forKey: .valueStyle) ?? .cumulative
        let decodedBasis = try container.decodeIfPresent(GoalAverageBasis.self, forKey: .averageBasis) ?? metric.defaultAverageBasis
        sessionScope = try container.decodeIfPresent(GoalSessionScope.self, forKey: .sessionScope) ?? .all
        valueStyle = metric.supportsValueStyle ? decodedStyle : .cumulative
        averageBasis = metric.supportsValueStyle ? decodedBasis : metric.defaultAverageBasis
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        starterGenerated = try container.decodeIfPresent(Bool.self, forKey: .starterGenerated) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(metric, forKey: .metric)
        try container.encode(target, forKey: .target)
        try container.encode(window, forKey: .window)
        if metric.supportsValueStyle {
            try container.encode(valueStyle, forKey: .valueStyle)
            try container.encode(averageBasis, forKey: .averageBasis)
        }
        try container.encode(sessionScope, forKey: .sessionScope)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(notes, forKey: .notes)
        try container.encode(isArchived, forKey: .isArchived)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
        try container.encode(starterGenerated, forKey: .starterGenerated)
    }
}

@MainActor
final class GoalsStore: ObservableObject {
    @Published var goals: [Goal] = []

    private let localURL: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("PoolStats", isDirectory: true)
        localURL = dir.appendingPathComponent("goals.json")
        loadLocal()
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
        saveLocal()
    }

    func applyStarterGoals(_ starterGoals: [Goal], replaceExistingStarter: Bool) {
        let existingStarterIDs = Set(goals.filter(\.starterGenerated).map(\.id))
        if replaceExistingStarter {
            goals.removeAll { existingStarterIDs.contains($0.id) }
            goals = starterGoals + goals
            saveLocal()
            return
        }

        let hasStarter = goals.contains(where: \.starterGenerated)
        guard !hasStarter else { return }
        goals = starterGoals + goals
        saveLocal()
    }

    private func loadLocal() {
        guard let data = try? Data(contentsOf: localURL) else { return }
        if let loaded = try? JSONDecoder().decode([Goal].self, from: data) {
            goals = loaded
        }
    }

    private func saveLocal() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(goals) else { return }
        let dir = localURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: localURL, options: Data.WritingOptions.atomic)
    }

    private static func sampleGoals() -> [Goal] {
        [
            Goal(title: "Open layouts to 55%", metric: .conversionRate, target: 55, window: .rolling(.init(amount: 30, unit: .sessions)), sessionScope: .match, starterGenerated: true),
            Goal(title: "Match win rate above 70%", metric: .matchWinRate, target: 70, window: .rolling(.init(amount: 10, unit: .sessions)), sessionScope: .match, starterGenerated: true),
            Goal(title: "Keep positional errors under 6 per rack", metric: .positionalErrors, target: 6, window: .rolling(.init(amount: 100, unit: .racks)), valueStyle: .average, averageBasis: .racks, sessionScope: .practice, starterGenerated: true),
            Goal(title: "Record 100 runouts by year end", metric: .runouts, target: 100, window: .dueDate(Calendar.current.date(from: DateComponents(year: Calendar.current.component(.year, from: Date()), month: 12, day: 31)) ?? Date()), valueStyle: .cumulative, starterGenerated: true),
            Goal(title: "Average 2 break-and-runs per week", metric: .breakAndRuns, target: 2, window: .rolling(.init(amount: 1, unit: .weeks)), valueStyle: .average, averageBasis: .sessions, sessionScope: .match, starterGenerated: true),
            Goal(title: "Average performance 7.0+", metric: .averagePerformance, target: 7.0, window: .rolling(.init(amount: 10, unit: .sessions)), sessionScope: .all, starterGenerated: true),
            Goal(title: "Keep miss errors under 8 per rack", metric: .missErrors, target: 8, window: .rolling(.init(amount: 30, unit: .sessions)), valueStyle: .average, averageBasis: .racks, sessionScope: .practice, starterGenerated: true)
        ]
    }
}
