import Foundation

extension WatchRack {
    mutating func apply(_ patch: WatchRackPatch) {
        if let value = patch.result { result = value }
        if let value = patch.breaker { breaker = value }
        if let value = patch.breakBalls { breakBalls = value }
        if let value = patch.breakFoul { breakFoul = value }
        if let value = patch.layout { layout = value }
        if let value = patch.outcome { outcome = value }
        if let value = patch.fouls { fouls = max(0, value) }
        if let value = patch.badSafety { badSafety = max(0, value) }
        if let value = patch.badPosition { badPosition = max(0, value) }
        if let value = patch.patternCount { patternCount = max(0, value) }
        if let value = patch.missCount { missCount = max(0, value) }
        if let value = patch.runoutFirst { runoutFirst = value }
        if let value = patch.breakAndRun { breakAndRun = value }
    }
}
