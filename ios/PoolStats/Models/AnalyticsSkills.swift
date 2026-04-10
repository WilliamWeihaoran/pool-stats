import Foundation

extension Analytics {
    static func radarScores(allSessions: [Session], filteredRacks: [Rack], mode: ModeFilter) -> [Int] {
        let n = Double(max(filteredRacks.count, 1))
        let pos = Double(filteredRacks.reduce(0) { $0 + $1.badPosition })
        let saf = Double(filteredRacks.reduce(0) { $0 + $1.badSafety })
        let fou = Double(filteredRacks.reduce(0) { $0 + $1.fouls })

        var tP: Double = 0
        var tA: Double = 0
        for s in allSessions {
            for r in s.racks {
                let p = Double(ep(r, game: s.game))
                tP += p
                tA += p + Double(r.missEasy + r.missMed + r.missHard)
            }
        }
        let pct = tA > 0 ? tP / tA : 0.72
        let posScore = tA > 0 ? Int(round((1 - pos / tA) * 100)) : 50

        let r8 = allSessions.filter { $0.game == "8ball" }.flatMap { $0.racks }
        let r9 = allSessions.filter { $0.game == "9ball" }.flatMap { $0.racks }
        let expSafe = Double(r8.count) * 0.5 + Double(r9.count) * 1.25
        let safeRate = expSafe > 0 ? saf / expSafe : 0
        let sScore = Int(round(max(0, 100 * (1 - log(1 + safeRate) / log(1 + 2.3)))))
        let fScore = Int(round(max(0, 100 * (1 - log(1 + fou / n) / log(4.5)))))

        func errCV(_ racks: [Rack]) -> Double {
            guard racks.count >= 2 else { return 0 }
            let errs = racks.map { $0.fouls + $0.badSafety + $0.badPosition + $0.planChange + $0.missEasy + $0.missMed + $0.missHard }
            let mean = Double(errs.reduce(0, +)) / Double(errs.count)
            if mean == 0 { return 0 }
            let variance = errs.reduce(0.0) { $0 + pow(Double($1) - mean, 2) } / Double(errs.count)
            return sqrt(variance) / mean
        }

        let mRacks = matchRacks(allSessions)
        var ww = 0, wwT = 0, wl = 0, wlT = 0
        if mRacks.count >= 2 {
            for i in 1..<mRacks.count {
                if mRacks[i - 1].result == "won" {
                    wwT += 1
                    if mRacks[i].result == "won" { ww += 1 }
                } else if mRacks[i - 1].result == "lost" {
                    wlT += 1
                    if mRacks[i].result == "won" { wl += 1 }
                }
            }
        }
        let wwR = wwT > 0 ? Double(ww) / Double(wwT) : nil
        let wlR = wlT > 0 ? Double(wl) / Double(wlT) : nil
        let streakScore: Int
        if let wwR, let wlR {
            streakScore = Int(round((wwR * 0.6 + wlR * 0.4) * 100))
        } else if let wwR {
            streakScore = Int(round(wwR * 100))
        } else if let wlR {
            streakScore = Int(round(wlR * 100))
        } else {
            streakScore = 50
        }
        let stabScore = Int(round(max(0, 100 * (1 - errCV(mRacks)))))

        let pracRacks = allSessions.filter { $0.type == "practice" }.flatMap { $0.racks }
        var ro = 0, roT = 0, roo = 0, rooT = 0
        if pracRacks.count >= 2 {
            for j in 1..<pracRacks.count {
                let prev = pracRacks[j - 1].outcome == "runout"
                let cur = pracRacks[j].outcome == "runout"
                if prev {
                    roT += 1
                    if cur { ro += 1 }
                } else {
                    rooT += 1
                    if cur { roo += 1 }
                }
            }
        }
        let roR = roT > 0 ? Double(ro) / Double(roT) : nil
        let rooR = rooT > 0 ? Double(roo) / Double(rooT) : nil
        let pracStreakScore: Int
        if let roR, let rooR {
            pracStreakScore = Int(round((roR * 0.6 + rooR * 0.4) * 100))
        } else if let roR {
            pracStreakScore = Int(round(roR * 100))
        } else if let rooR {
            pracStreakScore = Int(round(rooR * 100))
        } else {
            pracStreakScore = 50
        }
        let pracStabScore = Int(round(max(0, 100 * (1 - errCV(pracRacks)))))

        let consScore: Int
        if mode == .practice {
            consScore = Int(round(Double(pracStreakScore) * 0.5 + Double(pracStabScore) * 0.5))
        } else {
            consScore = Int(round(Double(streakScore) * 0.5 + Double(stabScore) * 0.5))
        }

        return [Int(round(pct * 100)), posScore, sScore, fScore, consScore]
    }

    static func ep(_ r: Rack, game: String) -> Int {
        let m = r.missEasy + r.missMed + r.missHard
        let oR = r.outcome == "runout" && r.result == "lost"
        let sB = r.outcome == "safety"
        let ru = r.outcome == "runout" && r.result == "won"
        if game == "8ball" {
            if r.result == "won" { return 8 }
            if r.result == nil { return 5 }
            let b: Double
            if oR && r.breaker == "opp" { b = 3 }
            else if oR { b = 3.5 }
            else if sB && r.breakBalls == 0 { b = 5.5 }
            else { b = 5 }
            return Int(round(max(1, min(7, b - min(Double(m) * 0.6, 3)))))
        }
        if r.result == "won" {
            if ru {
                let b2 = r.breaker == "me" ? 6.5 : 6.0
                return Int(round(max(3, min(7, b2 - Double(m) * 0.5))))
            }
            let base = r.outcome == "error" ? 4.0 : 5.0
            return Int(round(max(2, min(6, base - Double(m) * 0.6))))
        }
        if r.result == nil {
            return Int(round(max(2, min(6, 5.0 - Double(m) * 0.5))))
        }
        let base = (oR && r.breaker == "opp") ? 2.0 : (oR ? 3.0 : 4.0)
        return Int(round(max(1, min(5, base - Double(m) * 0.7))))
    }
}
