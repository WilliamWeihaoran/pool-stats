import Foundation

extension Analytics {
    static func insights(allRacks: [Rack], matchRacks: [Rack]) -> InsightsResult {
        let mBP = matchRacks.filter { $0.breaker == "me" && $0.breakBalls >= 1 }
        let mBD = matchRacks.filter { $0.breaker == "me" && $0.breakBalls == 0 }
        let myB = matchRacks.filter { $0.breaker == "me" }
        let oB = matchRacks.filter { $0.breaker == "opp" }
        func wr(_ arr: [Rack]) -> Int? {
            guard !arr.isEmpty else { return nil }
            let w = arr.filter { $0.result == "won" }.count
            return Int(round(Double(w) / Double(arr.count) * 100))
        }
        let breakCards: [(String, Int?)] = [
            ("Potted on break win%", wr(mBP)),
            ("Dry break win%", wr(mBD)),
            ("My break win%", wr(myB)),
            ("Opp break win%", wr(oB))
        ]

        let layouts = ["open", "clustered", "problematic", "snookered"]
        let layoutRates: [Int?] = layouts.map { l in
            let lr = allRacks.filter { $0.layout == l }
            guard !lr.isEmpty else { return nil }
            let w = lr.filter { $0.result == "won" }.count
            return Int(round(Double(w) / Double(lr.count) * 100))
        }

        return InsightsResult(breakCards: breakCards, layoutRates: layoutRates)
    }
}
