import Foundation

struct DrillPoint: Codable, Hashable {
    var x: Double
    var y: Double
}

struct DrillBall: Codable, Hashable, Identifiable {
    var id: String
    var number: Int?
    var label: String
    var position: DrillPoint
    var colorName: String
}

struct DrillZone: Codable, Hashable, Identifiable {
    var id: String
    var label: String
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var colorName: String
    var isForbidden: Bool
}

struct GeneratedDrill: Codable, Hashable {
    var templateID: String
    var seed: UInt64
    var balls: [DrillBall]
    var zones: [DrillZone]
    var instructions: [String]
    var constraints: [String]
}

struct DrillTemplate: Identifiable, Hashable {
    var id: String
    var title: String
    var subtitle: String
    var difficulty: String
    var accentName: String
    var ballRange: ClosedRange<Int>
}

struct DrillRun: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var templateID: String
    var title: String
    var generated: GeneratedDrill
    var startedAt: Date = Date()
    var endedAt: Date?
    var attempts: Int = 0
    var successes: Int = 0
    var misses: Int = 0
    var notes: String = ""

    var isActive: Bool { endedAt == nil }
    var successRate: Int? {
        guard attempts > 0 else { return nil }
        return Int(round(Double(successes) / Double(attempts) * 100))
    }
}

enum DrillLibrary {
    static let templates: [DrillTemplate] = [
        DrillTemplate(
            id: "one_side_pattern",
            title: "One-side pattern",
            subtitle: "Clear 3-5 balls in order without side spin or crossing the table.",
            difficulty: "Control",
            accentName: "teal",
            ballRange: 3...5
        ),
        DrillTemplate(
            id: "stop_shot_ladder",
            title: "Stop-shot ladder",
            subtitle: "Move up the ladder and stop the cue ball cleanly after each pot.",
            difficulty: "Fundamentals",
            accentName: "green",
            ballRange: 4...5
        ),
        DrillTemplate(
            id: "centerline_control",
            title: "Centerline control",
            subtitle: "Pot random balls while bringing the cue ball back to the center lane.",
            difficulty: "Position",
            accentName: "blue",
            ballRange: 4...6
        ),
        DrillTemplate(
            id: "rail_avoidance",
            title: "Rail avoidance pattern",
            subtitle: "Clear the layout while keeping cue ball travel away from the long rails.",
            difficulty: "Cue ball",
            accentName: "amber",
            ballRange: 4...6
        ),
        DrillTemplate(
            id: "open_table_runout",
            title: "Open-table runout mini",
            subtitle: "A small open-layout runout with no clusters. Take balls in order.",
            difficulty: "Runout",
            accentName: "purple",
            ballRange: 4...6
        )
    ]

    static func template(id: String) -> DrillTemplate? {
        templates.first { $0.id == id }
    }

    static func generate(templateID: String, seed: UInt64 = Self.newSeed()) -> GeneratedDrill {
        var rng = DrillRNG(seed: seed)
        switch templateID {
        case "one_side_pattern":
            return oneSidePattern(seed: seed, rng: &rng)
        case "stop_shot_ladder":
            return stopShotLadder(seed: seed, rng: &rng)
        case "centerline_control":
            return centerlineControl(seed: seed, rng: &rng)
        case "rail_avoidance":
            return railAvoidance(seed: seed, rng: &rng)
        default:
            return openTableRunout(seed: seed, rng: &rng)
        }
    }

    static func newSeed() -> UInt64 {
        UInt64.random(in: 1...UInt64.max)
    }

    private static func oneSidePattern(seed: UInt64, rng: inout DrillRNG) -> GeneratedDrill {
        let leftSide = rng.chance(0.5)
        let count = rng.nextInt(3, 5)
        let xRange: ClosedRange<Double> = leftSide ? 0.16...0.46 : 0.54...0.84
        let objectPoints = randomPoints(count: count, xRange: xRange, yRange: 0.18...0.82, minDistance: 0.09, rng: &rng)
        let cueX = leftSide ? 0.28 : 0.72
        let forbiddenX = leftSide ? 0.5 : 0.08
        let cue = ball(number: nil, label: "C", x: cueX, y: 0.5, color: "white")
        return GeneratedDrill(
            templateID: "one_side_pattern",
            seed: seed,
            balls: [cue] + numberedBalls(objectPoints),
            zones: [
                DrillZone(id: "forbidden_half", label: "Do not cross", x: forbiddenX, y: 0.08, width: 0.42, height: 0.84, colorName: "red", isForbidden: true)
            ],
            instructions: [
                "Scatter the numbered balls on one side of the table.",
                "Pot balls in numerical order.",
                "Use center-ball only: stun, follow, and draw are allowed, but no side spin."
            ],
            constraints: [
                "Cue ball may not cross the table centerline.",
                "No side spin.",
                "Restart after a miss or failed position."
            ]
        )
    }

    private static func stopShotLadder(seed: UInt64, rng: inout DrillRNG) -> GeneratedDrill {
        let yBase = 0.5
        let points = [0.38, 0.50, 0.62, 0.74].map { DrillPoint(x: $0, y: yBase + rng.nextDouble(in: -0.035...0.035)) }
        return GeneratedDrill(
            templateID: "stop_shot_ladder",
            seed: seed,
            balls: [ball(number: nil, label: "C", x: 0.22, y: yBase, color: "white")] + numberedBalls(points),
            zones: [
                DrillZone(id: "stop_zone", label: "Stop zone", x: 0.17, y: 0.43, width: 0.1, height: 0.14, colorName: "green", isForbidden: false)
            ],
            instructions: [
                "Shoot each object ball to the far corner or side pocket that feels natural.",
                "After contact, the cue ball should stop inside the stop zone.",
                "Move to the next ball only after a clean stop."
            ],
            constraints: [
                "Count only shots where the cue ball stops cleanly.",
                "No drifting more than a diamond from the original cue-ball line."
            ]
        )
    }

    private static func centerlineControl(seed: UInt64, rng: inout DrillRNG) -> GeneratedDrill {
        let count = rng.nextInt(4, 6)
        let points = randomPoints(count: count, xRange: 0.18...0.82, yRange: 0.18...0.82, minDistance: 0.1, rng: &rng)
        return GeneratedDrill(
            templateID: "centerline_control",
            seed: seed,
            balls: [ball(number: nil, label: "C", x: 0.5, y: 0.5, color: "white")] + numberedBalls(points),
            zones: [
                DrillZone(id: "center_lane", label: "Center lane", x: 0.12, y: 0.42, width: 0.76, height: 0.16, colorName: "blue", isForbidden: false)
            ],
            instructions: [
                "Pot the balls in order.",
                "After every shot, bring the cue ball back into the center lane.",
                "Choose pockets that make the next route natural."
            ],
            constraints: [
                "A shot scores only if the cue ball finishes in the center lane.",
                "Avoid bumping other object balls."
            ]
        )
    }

    private static func railAvoidance(seed: UInt64, rng: inout DrillRNG) -> GeneratedDrill {
        let count = rng.nextInt(4, 6)
        let points = randomPoints(count: count, xRange: 0.18...0.82, yRange: 0.22...0.78, minDistance: 0.1, rng: &rng)
        return GeneratedDrill(
            templateID: "rail_avoidance",
            seed: seed,
            balls: [ball(number: nil, label: "C", x: 0.24, y: 0.5, color: "white")] + numberedBalls(points),
            zones: [
                DrillZone(id: "top_rail", label: "Avoid rail", x: 0.08, y: 0.08, width: 0.84, height: 0.12, colorName: "red", isForbidden: true),
                DrillZone(id: "bottom_rail", label: "Avoid rail", x: 0.08, y: 0.80, width: 0.84, height: 0.12, colorName: "red", isForbidden: true)
            ],
            instructions: [
                "Clear the balls in order.",
                "Plan routes that keep the cue ball away from the long rails.",
                "Use soft speed and natural angles."
            ],
            constraints: [
                "Cue ball may not finish in a red rail zone.",
                "Restart if you contact a forbidden rail zone after the shot."
            ]
        )
    }

    private static func openTableRunout(seed: UInt64, rng: inout DrillRNG) -> GeneratedDrill {
        let count = rng.nextInt(4, 6)
        let points = randomPoints(count: count, xRange: 0.14...0.86, yRange: 0.16...0.84, minDistance: 0.13, rng: &rng)
        return GeneratedDrill(
            templateID: "open_table_runout",
            seed: seed,
            balls: [ball(number: nil, label: "C", x: rng.nextDouble(in: 0.22...0.36), y: rng.nextDouble(in: 0.32...0.68), color: "white")] + numberedBalls(points),
            zones: [],
            instructions: [
                "Pot the balls in numerical order.",
                "Treat it like a small open-table runout.",
                "Regenerate if the route feels too easy or too crowded."
            ],
            constraints: [
                "No intentional clusters.",
                "Take ball in hand only before the first shot."
            ]
        )
    }

    private static func ball(number: Int?, label: String, x: Double, y: Double, color: String) -> DrillBall {
        DrillBall(id: UUID().uuidString, number: number, label: label, position: DrillPoint(x: x, y: y), colorName: color)
    }

    private static func numberedBalls(_ points: [DrillPoint]) -> [DrillBall] {
        let colors = ["yellow", "blue", "red", "purple", "orange", "green"]
        return points.enumerated().map { idx, point in
            let n = idx + 1
            return ball(number: n, label: "\(n)", x: point.x, y: point.y, color: colors[idx % colors.count])
        }
    }

    private static func randomPoints(
        count: Int,
        xRange: ClosedRange<Double>,
        yRange: ClosedRange<Double>,
        minDistance: Double,
        rng: inout DrillRNG
    ) -> [DrillPoint] {
        var points: [DrillPoint] = []
        var attempts = 0
        while points.count < count && attempts < 2_000 {
            attempts += 1
            let candidate = DrillPoint(x: rng.nextDouble(in: xRange), y: rng.nextDouble(in: yRange))
            guard points.allSatisfy({ distance($0, candidate) >= minDistance }) else { continue }
            points.append(candidate)
        }
        while points.count < count {
            points.append(DrillPoint(x: xRange.lowerBound + (xRange.upperBound - xRange.lowerBound) * 0.5,
                                     y: yRange.lowerBound + (yRange.upperBound - yRange.lowerBound) * Double(points.count + 1) / Double(count + 1)))
        }
        return points
    }

    private static func distance(_ a: DrillPoint, _ b: DrillPoint) -> Double {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return (dx * dx + dy * dy).squareRoot()
    }
}

struct DrillRNG {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1
        return state
    }

    mutating func nextDouble() -> Double {
        Double(next() % 10_000) / 10_000.0
    }

    mutating func nextDouble(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + nextDouble() * (range.upperBound - range.lowerBound)
    }

    mutating func nextInt(_ min: Int, _ max: Int) -> Int {
        guard max >= min else { return min }
        return min + Int(next() % UInt64(max - min + 1))
    }

    mutating func chance(_ probability: Double) -> Bool {
        nextDouble() < probability
    }
}

@MainActor
final class DrillStore: ObservableObject {
    @Published private(set) var runs: [DrillRun] = []
    @Published private(set) var activeRun: DrillRun?

    private let localURL: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("PoolStats", isDirectory: true)
        localURL = dir.appendingPathComponent("drill_runs.json")
        loadLocal()
        activeRun = runs.first(where: { $0.isActive })
    }

    func startRun(template: DrillTemplate) {
        if let activeID = activeRun?.id, let idx = runs.firstIndex(where: { $0.id == activeID }) {
            runs[idx].endedAt = Date()
        }
        var run = DrillRun(
            templateID: template.id,
            title: template.title,
            generated: DrillLibrary.generate(templateID: template.id)
        )
        run.startedAt = Date()
        runs.insert(run, at: 0)
        activeRun = run
        saveLocal()
    }

    func regenerateActiveLayout() {
        updateActiveRun { run in
            let nextSeed = DrillLibrary.newSeed()
            run.generated = DrillLibrary.generate(templateID: run.templateID, seed: nextSeed)
        }
    }

    func recordAttempt(runID: String? = nil) {
        updateRun(id: runID ?? activeRun?.id) { run in
            run.attempts += 1
        }
    }

    func recordSuccess(runID: String? = nil) {
        updateRun(id: runID ?? activeRun?.id) { run in
            run.attempts += 1
            run.successes += 1
        }
    }

    func recordMiss(runID: String? = nil) {
        updateRun(id: runID ?? activeRun?.id) { run in
            run.attempts += 1
            run.misses += 1
        }
    }

    func updateNotes(_ notes: String) {
        updateActiveRun { run in
            run.notes = notes
        }
    }

    func finishActiveRun() {
        updateActiveRun { run in
            run.endedAt = Date()
        }
        activeRun = nil
        saveLocal()
    }

    func snapshotForWatch() -> WatchDrillSnapshot? {
        guard let activeRun else { return nil }
        return WatchDrillSnapshot(
            runID: activeRun.id,
            title: activeRun.title,
            attempts: activeRun.attempts,
            successes: activeRun.successes,
            misses: activeRun.misses
        )
    }

    private func updateActiveRun(_ mutate: (inout DrillRun) -> Void) {
        updateRun(id: activeRun?.id, mutate)
    }

    private func updateRun(id: String?, _ mutate: (inout DrillRun) -> Void) {
        guard let id, let idx = runs.firstIndex(where: { $0.id == id }) else { return }
        mutate(&runs[idx])
        if activeRun?.id == id {
            activeRun = runs[idx]
        }
        saveLocal()
    }

    private func loadLocal() {
        guard let data = try? Data(contentsOf: localURL),
              let decoded = try? JSONDecoder().decode([DrillRun].self, from: data) else { return }
        runs = decoded.sorted { lhs, rhs in
            if lhs.startedAt != rhs.startedAt { return lhs.startedAt > rhs.startedAt }
            return lhs.id > rhs.id
        }
    }

    private func saveLocal() {
        guard let data = try? JSONEncoder().encode(runs) else { return }
        let dir = localURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: localURL, options: .atomic)
    }
}
