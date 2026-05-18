import Foundation

extension Analytics {
    static func mistakesPerRack(_ racks: [Rack]) -> [MetricItem] {
        let n = Double(max(racks.count, 1))
        func sum(_ key: KeyPath<Rack, Int>) -> Double {
            Double(racks.reduce(0) { $0 + $1[keyPath: key] })
        }
        return [
            MetricItem(label: NSLocalizedString("Miss", comment: ""), value: sum(\.missCount) / n),
            MetricItem(label: NSLocalizedString("Position", comment: ""), value: sum(\.positionTrackingCount) / n),
            MetricItem(label: NSLocalizedString("Safety", comment: ""), value: sum(\.badSafety) / n),
            MetricItem(label: NSLocalizedString("Pattern", comment: ""), value: sum(\.patternMistakeCount) / n)
        ]
    }

    static func wonLostItems(_ racks: [Rack]) -> (items: [WLItem], lossText: String) {
        let won = racks.filter { $0.result == "won" }
        let lost = racks.filter { $0.result == "lost" }
        let wA = mistakesPerRack(won)
        let lA = mistakesPerRack(lost)
        let order = wA.map { $0.label }
        var paired: [WLItem] = order.map { label in
            let w = wA.first { $0.label == label }?.value ?? 0
            let l = lA.first { $0.label == label }?.value ?? 0
            return WLItem(label: label, won: w, lost: l)
        }
        paired.sort { $0.lost > $1.lost }

        var maxDiff: Double = 0
        var tf: String = ""
        for p in paired {
            let d = p.lost - p.won
            if d > maxDiff {
                maxDiff = d
                tf = p.label
            }
        }
        let lossText: String
        if tf.isEmpty {
            lossText = NSLocalizedString("Not enough data yet.", comment: "")
        } else {
            lossText = AppLanguageRuntime.localizedFormat(
                "Biggest loss factor: %@ (+%.2f/rack in losses)",
                tf,
                maxDiff
            )
        }

        return (paired, lossText)
    }

    static func biggestLeakSummary(_ racks: [Rack]) -> String {
        let (items, _) = wonLostItems(racks)
        guard let leak = items.max(by: { ($0.lost - $0.won) < ($1.lost - $1.won) }) else {
            return NSLocalizedString("Not enough data yet.", comment: "")
        }
        let diff = leak.lost - leak.won
        guard diff > 0 else {
            return NSLocalizedString("No clear leak yet.", comment: "")
        }
        return AppLanguageRuntime.localizedFormat("%@ (+%.2f/rack)", leak.label, diff)
    }

    static func outcomeCounts(sessions: [Session], target: OutcomeTarget) -> (wins: Int, losses: Int) {
        let mSessions = matchOnly(sessions)
        let mRacks = matchRacks(sessions)
        let mW = mSessions.filter { s in
            let w = s.racks.filter { $0.result == "won" }.count
            return w > s.racks.count / 2
        }.count
        let mL = mSessions.count - mW
        let rW = mRacks.filter { $0.result == "won" }.count
        let rL = mRacks.count - rW
        if target == .match {
            return (mW, mL)
        }
        return (rW, rL)
    }
}
