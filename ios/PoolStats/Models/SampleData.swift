import Foundation

struct SampleData {
    struct SeededRNG {
        private var state: UInt64
        init(seed: UInt64) { self.state = seed }
        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1
            return state
        }
        mutating func nextDouble() -> Double {
            Double(next() % 10_000) / 10_000.0
        }
        mutating func nextInt(_ min: Int, _ max: Int) -> Int {
            guard max >= min else { return min }
            let span = UInt64(max - min + 1)
            return min + Int(next() % span)
        }
        mutating func chance(_ p: Double) -> Bool {
            nextDouble() < p
        }
    }

    static func makeSessions(count: Int = 50, seed: UInt64 = 42) -> [Session] {
        var rng = SeededRNG(seed: seed)
        var out: [Session] = []
        let now = Date()
        let layouts = ["open", "clustered", "problematic", "snookered"]

        for i in 0..<count {
            let game = rng.chance(0.6) ? "8ball" : "9ball"
            let isPr = rng.chance(0.2)
            let daysAgo = rng.nextInt(0, 364)
            let ts = now.addingTimeInterval(TimeInterval(-daysAgo * 86_400))
            let racksCount = rng.nextInt(3, 8)

            var racks: [Rack] = []
            for j in 0..<racksCount {
                let res: String? = isPr ? nil : (rng.chance(0.54) ? "won" : "lost")
                let brk = rng.chance(0.55) ? "me" : "opp"
                let bb = rng.nextInt(0, 3)
                let lay = layouts[rng.nextInt(0, 3)]

                let oc: String
                if rng.chance(0.25) { oc = "runout" }
                else if rng.chance(0.3) { oc = "error" }
                else if rng.chance(0.5) { oc = "safety" }
                else { oc = "other" }

                let m = rng.nextInt(0, 4)
                let mE = rng.nextInt(0, min(m, 2))
                let mM = rng.nextInt(0, min(m - mE, 2))
                let mH = max(0, m - mE - mM)

                let ru = oc == "runout" && res == "won" && rng.chance(0.6)
                let bnr = ru && brk == "me" && bb >= 1

                let rack = Rack(
                    index: j + 1,
                    result: res,
                    breaker: brk,
                    breakBalls: bb,
                    breakFoul: rng.chance(0.05),
                    layout: lay,
                    outcome: oc,
                    fouls: rng.nextInt(0, 2),
                    badSafety: rng.nextInt(0, 2),
                    badPosition: rng.nextInt(0, 2),
                    planChange: rng.nextInt(0, 2),
                    missEasy: mE,
                    missMed: mM,
                    missHard: mH,
                    runoutFirst: ru,
                    breakAndRun: bnr
                )
                racks.append(rack)
            }

            let label = isPr ? "Practice" : "Sample"
            let sess = Session(
                id: Int64(now.timeIntervalSince1970 * 1000) + Int64(i * 7),
                label: label,
                game: game,
                type: isPr ? "practice" : "match",
                ts: ts,
                racks: racks
            )
            out.append(sess)
        }

        return out
    }
}
