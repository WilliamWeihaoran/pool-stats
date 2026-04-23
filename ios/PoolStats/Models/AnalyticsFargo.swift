import Foundation

extension Analytics {
    static func fargoResult(matchSessions: [Session]) -> FargoResult {
        let racks = matchSessions.flatMap { $0.racks }

        let missErrors = Double(racks.reduce(0) { $0 + $1.missCount })
        let positionalErrors = Double(racks.reduce(0) { $0 + $1.badPosition })
        let safetyErrors = Double(racks.reduce(0) { $0 + $1.badSafety })
        let foulErrors = Double(racks.reduce(0) { $0 + $1.fouls })
        let unforcedTotal = missErrors + positionalErrors + safetyErrors + foulErrors

        // Potting / positional are "raw %" derived from unforced-error composition.
        let pottingPct = unforcedTotal > 0 ? (1 - missErrors / unforcedTotal) * 100 : 50
        let positionalPct = unforcedTotal > 0 ? (1 - positionalErrors / unforcedTotal) * 100 : 50

        let runouts = Double(racks.filter { $0.outcome == "runout" }.count)
        let openLayouts = Double(racks.filter { $0.layout == "open" }.count)
        let nonRunnableRunouts = Double(racks.filter { $0.layout != "open" && $0.layout != "none" && $0.outcome == "runout" }.count)
        let runnableAdjusted = openLayouts + nonRunnableRunouts
        // User rule: runout from non-runnable layout adds +1 to both numerator and denominator.
        let runoutPct = runnableAdjusted > 0 ? (runouts / runnableAdjusted) * 100 : 50

        let openRunouts = Double(racks.filter { $0.layout == "open" && $0.outcome == "runout" }.count)
        let openWithErrors = Double(racks.filter { $0.layout == "open" && $0.unforcedErrorCount > 0 }.count)
        let nonRunnableLayouts = Double(racks.filter { $0.layout != "open" && $0.layout != "none" }.count)
        let nonRunnableRunoutPct = nonRunnableLayouts > 0 ? (nonRunnableRunouts / nonRunnableLayouts) * 100 : 50
        let openRunoutPct = openLayouts > 0 ? (openRunouts / openLayouts) * 100 : 50
        let openCleanPct = openLayouts > 0 ? (1 - openWithErrors / openLayouts) * 100 : 50
        // Pattern play: reward hard-layout runouts, penalize errors on runnable/open layouts.
        let patternPct = 0.45 * openRunoutPct + 0.35 * nonRunnableRunoutPct + 0.20 * openCleanPct

        let myBreaks = racks.filter { $0.breaker == "me" }
        let myBreakCount = Double(myBreaks.count)
        let myBreaksWithBalls = myBreaks.filter { $0.breakBalls >= 0 }
        let ballsAvg = myBreaksWithBalls.isEmpty
            ? 1.0
            : Double(myBreaksWithBalls.reduce(0) { $0 + max(0, $1.breakBalls) }) / Double(myBreaksWithBalls.count)
        let breakBallsPct = clamp((ballsAvg / 2.0) * 100, min: 0, max: 100)

        let myBreakOpenLayouts = myBreaks.filter { $0.layout == "open" }.count
        let openCreatedPct = myBreakCount > 0 ? (Double(myBreakOpenLayouts) / myBreakCount) * 100 : 50
        let myBreakFouls = myBreaks.filter(\.breakFoul).count
        let breakDisciplinePct = myBreakCount > 0 ? (1 - Double(myBreakFouls) / myBreakCount) * 100 : 50
        let foulSafetyPct = unforcedTotal > 0 ? (1 - (foulErrors + safetyErrors) / unforcedTotal) * 100 : 50
        // Overall game: foul+safety discipline + break quality (balls, open layouts, break fouls).
        let overallGamePct = 0.35 * foulSafetyPct + 0.25 * breakBallsPct + 0.25 * openCreatedPct + 0.15 * breakDisciplinePct

        let values = [
            clamp(pottingPct, min: 0, max: 100),
            clamp(positionalPct, min: 0, max: 100),
            clamp(patternPct, min: 0, max: 100),
            clamp(runoutPct, min: 0, max: 100),
            clamp(overallGamePct, min: 0, max: 100)
        ]
        let weights: [Double] = [0.25, 0.20, 0.20, 0.20, 0.15]
        let weightedPct = zip(values, weights).reduce(0.0) { $0 + $1.0 * $1.1 }

        let estimated = Int(round(clamp(300 + weightedPct * 4.5, min: 300, max: 750)))
        let rangeText = "\(estimated - 25)–\(estimated + 25)"

        let names = ["Potting", "Position", "Pattern", "Runout", "Overall"]
        let weightTexts = ["25%", "20%", "20%", "20%", "15%"]
        let factors: [FargoFactor] = Array(0..<names.count).map { idx in
            let impact = 300 + values[idx] * 4.5
            let contribution = Int(round((impact - 500) * weights[idx]))
            return FargoFactor(name: names[idx],
                               scoreValue: Int(round(values[idx])),
                               valueText: String(format: "%.0f%%", values[idx]),
                               weightText: weightTexts[idx],
                               contribution: contribution)
        }

        return FargoResult(estimatedScore: estimated, rangeText: rangeText, factors: factors)
    }
}
