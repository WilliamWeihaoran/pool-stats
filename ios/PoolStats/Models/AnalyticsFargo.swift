import Foundation

extension Analytics {
    static func fargoResult(matchSessions: [Session]) -> FargoResult {
        let racks = matchSessions.flatMap { $0.racks }
        let n = Double(max(racks.count, 1))
        func sLog(_ v: Double, _ b: Double) -> Double { v > 0 && b > 0 ? log(v / b) : 0 }

        let rR = Double(racks.filter { $0.outcome == "runout" && $0.result == "won" }.count) / n
        let bR = Double(racks.filter { $0.breakAndRun }.count) / n
        let eM = Double(racks.reduce(0) { $0 + $1.missEasy }) / n
        let eR = Double(racks.reduce(0) { $0 + $1.fouls + $1.badSafety + $1.badPosition + $1.missEasy + $1.missMed + $1.missHard }) / n

        var tP: Double = 0
        var tA: Double = 0
        for s in matchSessions {
            for r in s.racks {
                let p = Double(ep(r, game: s.game))
                tP += p
                tA += p + Double(r.missEasy + r.missMed + r.missHard)
            }
        }
        let pPct = tA > 0 ? tP / tA : 0.72

        let rI = clamp(500 + 180 * sLog(max(rR, 0.001), 0.13), min: 300, max: 750)
        let bI = clamp(500 + 120 * sLog(max(bR, 0.001), 0.04), min: 300, max: 750)
        let pI = clamp(500 + 250 * (pPct - 0.72), min: 300, max: 750)
        let eI = clamp(500 - 150 * (eM - 0.20), min: 300, max: 750)
        let errI = clamp(500 - 35 * (eR - 4), min: 300, max: 750)

        let ws: [Double] = [0.35, 0.15, 0.25, 0.15, 0.10]
        let imp: [Double] = [rI, bI, pI, eI, errI]
        let fg = Int(round(zip(imp, ws).reduce(0) { $0 + $1.0 * $1.1 }))

        let facts: [(String, Double, (Double) -> String, String, Double)] = [
            ("Runout rate", rR, { String(format: "%.0f%%", $0 * 100) }, "35%", rI),
            ("Break & run", bR, { String(format: "%.1f%%", $0 * 100) }, "15%", bI),
            ("Potting", pPct, { String(format: "%.0f%%", $0 * 100) }, "25%", pI),
            ("Easy misses", eM, { String(format: "%.2f/rack", $0) }, "15%", eI),
            ("Errors/rack", eR, { String(format: "%.2f/rack", $0) }, "10%", errI)
        ]

        let factors: [FargoFactor] = facts.enumerated().map { i, f in
            let contrib = Int(round((f.4 - 500) * ws[i]))
            return FargoFactor(name: f.0, valueText: f.2(f.1), weightText: f.3, contribution: contrib)
        }

        let rangeText = "\(fg - 25)–\(fg + 25)"
        return FargoResult(rangeText: rangeText, factors: factors)
    }
}
