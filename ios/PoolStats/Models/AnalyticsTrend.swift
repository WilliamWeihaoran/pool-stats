import Foundation

extension Analytics {
    static func trendSeries(sessions: [Session], timeFilter: TimeFilter) -> TrendSeries {
        let sorted = sessions.sorted { $0.ts < $1.ts }
        guard sorted.count >= 2 else {
            return TrendSeries(labels: [], match: [], rack: [])
        }
        let now = Date()
        var buckets: [(start: Date, end: Date, sessions: [Session])] = []
        var labels: [String] = []
        let cal = Calendar.current

        if timeFilter == .all || timeFilter == .year {
            var months: [Int: [Session]] = [:]
            for s in sorted {
                let comps = cal.dateComponents([.year, .month], from: s.ts)
                let key = (comps.year ?? 0) * 100 + (comps.month ?? 0)
                months[key, default: []].append(s)
            }
            let keys = months.keys.sorted()
            let multiYear = Set(keys.map { $0 / 100 }).count > 1
            for key in keys {
                let list = months[key] ?? []
                let year = key / 100
                let month = key % 100
                let start = cal.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
                let end = cal.date(byAdding: .month, value: 1, to: start) ?? start
                buckets.append((start, end, list))
                if let year = key / 100 as Int?, let month = key % 100 as Int? {
                    let date = cal.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
                    labels.append(multiYear ? shortMonthYear(date) : shortMonth(date))
                } else {
                    labels.append(shortMonth(Date()))
                }
            }
        } else if timeFilter == .threeMonths {
            let span: TimeInterval = 14 * 86_400
            var t = now.addingTimeInterval(TimeInterval(-timeFilter.rawValue * 86_400))
            while t < now {
                let e = min(t.addingTimeInterval(span), now)
                let list = sorted.filter { $0.ts >= t && $0.ts < e }
                buckets.append((t, e, list))
                labels.append(rangeLabel(start: t, end: e, calendar: cal))
                t = e
            }
        } else if timeFilter == .month {
            let span: TimeInterval = 7 * 86_400
            var t = now.addingTimeInterval(TimeInterval(-timeFilter.rawValue * 86_400))
            while t < now {
                let e = min(t.addingTimeInterval(span), now)
                let list = sorted.filter { $0.ts >= t && $0.ts < e }
                buckets.append((t, e, list))
                labels.append(rangeLabel(start: t, end: e, calendar: cal))
                t = e
            }
        } else if timeFilter == .week {
            let span: TimeInterval = 86_400
            var t = now.addingTimeInterval(TimeInterval(-timeFilter.rawValue * 86_400))
            while t < now {
                let e = min(t.addingTimeInterval(span), now)
                let list = sorted.filter { $0.ts >= t && $0.ts < e }
                buckets.append((t, e, list))
                labels.append(shortMonthDay(t))
                t = e
            }
        } else {
            buckets.append((now, now, sorted))
            labels.append("Today")
        }

        var matchVals: [Double?] = []
        var rackVals: [Double?] = []
        for bucket in buckets {
            let b = bucket.sessions
            if b.isEmpty {
                matchVals.append(nil)
                rackVals.append(nil)
                continue
            }
            let mW = b.filter { s in
                let w = s.racks.filter { $0.result == "won" }.count
                return w > s.racks.count / 2
            }.count
            let rs = b.flatMap { $0.racks }
            let rW = rs.filter { $0.result == "won" }.count
            matchVals.append(Double(mW) / Double(b.count) * 100.0)
            rackVals.append(rs.isEmpty ? nil : Double(rW) / Double(rs.count) * 100.0)
        }

        let compressed = compressSeries(labels: labels, match: matchVals, rack: rackVals)
        return TrendSeries(labels: compressed.labels, match: compressed.match, rack: compressed.rack)
    }

    private static func shortMonth(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMM"
        return f.string(from: date)
    }

    private static func shortMonthYear(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMM yy"
        return f.string(from: date)
    }

    private static func shortMonthDay(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    private static func rangeLabel(start: Date, end: Date, calendar: Calendar) -> String {
        let sameYear = calendar.component(.year, from: start) == calendar.component(.year, from: end)
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = sameYear ? "MMM d" : "MMM d, yy"
        let left = df.string(from: start)
        let right = df.string(from: calendar.date(byAdding: .day, value: -1, to: end) ?? end)
        return "\(left)–\(right)"
    }

    private static func compressSeries(labels: [String], match: [Double?], rack: [Double?]) -> TrendSeries {
        guard labels.count == match.count, labels.count == rack.count else {
            return TrendSeries(labels: labels, match: match, rack: rack)
        }

        var order: [String] = []
        var buckets: [String: (match: [Double], rack: [Double])] = [:]

        for idx in labels.indices {
            let key = labels[idx]
            if buckets[key] == nil {
                buckets[key] = ([], [])
                order.append(key)
            }
            if let v = match[idx] { buckets[key]?.match.append(v) }
            if let v = rack[idx] { buckets[key]?.rack.append(v) }
        }

        var outLabels: [String] = []
        var outMatch: [Double?] = []
        var outRack: [Double?] = []
        for key in order {
            guard let b = buckets[key] else { continue }
            outLabels.append(key)
            outMatch.append(b.match.isEmpty ? nil : b.match.reduce(0, +) / Double(b.match.count))
            outRack.append(b.rack.isEmpty ? nil : b.rack.reduce(0, +) / Double(b.rack.count))
        }
        return TrendSeries(labels: outLabels, match: outMatch, rack: outRack)
    }
}
