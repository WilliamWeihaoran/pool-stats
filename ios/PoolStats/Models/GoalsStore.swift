import Foundation

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
