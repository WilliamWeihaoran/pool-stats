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
    var planChange: Int
    var missEasy: Int
    var missMed: Int
    var missHard: Int
    var runoutFirst: Bool
    var breakAndRun: Bool

    init(
        id: String = UUID().uuidString,
        index: Int,
        result: String? = nil,
        breaker: String = "none",
        breakBalls: Int = -1,
        breakFoul: Bool = false,
        layout: String = "open",
        outcome: String? = nil,
        fouls: Int = 0,
        badSafety: Int = 0,
        badPosition: Int = 0,
        planChange: Int = 0,
        missEasy: Int = 0,
        missMed: Int = 0,
        missHard: Int = 0,
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
        self.planChange = planChange
        self.missEasy = missEasy
        self.missMed = missMed
        self.missHard = missHard
        self.runoutFirst = runoutFirst
        self.breakAndRun = breakAndRun
    }
}
