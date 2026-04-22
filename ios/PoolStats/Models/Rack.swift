import Foundation

struct Rack: Identifiable, Codable, Hashable {
    var id: String
    var index: Int
    var result: String?
    var breaker: String
    var breakBalls: Int
    var breakFoul: Bool
    var layout: String
    var outcome: String?
    var fouls: Int
    var badSafety: Int
    var badPosition: Int
    var missCount: Int
    var runoutFirst: Bool
    var breakAndRun: Bool

    var converted: Bool { outcome == "runout" }
    var isNoRunout: Bool { outcome == "noRunout" }
    var positionalCount: Int { badPosition }
    var safetyCount: Int { badSafety }
    var foulCount: Int { fouls }
    var unforcedErrorCount: Int { foulCount + safetyCount + positionalCount + missCount }

    init(
        id: String = UUID().uuidString,
        index: Int,
        result: String? = nil,
        breaker: String = "none",
        breakBalls: Int = -1,
        breakFoul: Bool = false,
        layout: String = "none",
        outcome: String? = nil,
        fouls: Int = 0,
        badSafety: Int = 0,
        badPosition: Int = 0,
        missCount: Int = 0,
        runoutFirst: Bool = false,
        breakAndRun: Bool = false
    ) {
        self.id = id
        self.index = index
        self.result = result
        self.breaker = breaker
        self.breakBalls = breakBalls
        self.breakFoul = breakFoul
        self.layout = layout
        self.outcome = outcome
        self.fouls = fouls
        self.badSafety = badSafety
        self.badPosition = badPosition
        self.missCount = missCount
        self.runoutFirst = runoutFirst
        self.breakAndRun = breakAndRun
    }
}
