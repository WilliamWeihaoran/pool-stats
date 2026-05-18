import Foundation

enum SkillLevel: String, Codable, CaseIterable, Identifiable {
    case novice
    case beginner
    case intermediate
    case advanced
    case pro

    var id: String { rawValue }

    var label: String {
        switch self {
        case .novice: return NSLocalizedString("Beginner", comment: "")
        case .beginner: return NSLocalizedString("Developing", comment: "")
        case .intermediate: return NSLocalizedString("Intermediate", comment: "")
        case .advanced: return NSLocalizedString("Advanced", comment: "")
        case .pro: return NSLocalizedString("Pro", comment: "")
        }
    }

    var fargoRange: String {
        switch self {
        case .novice: return "100–300"
        case .beginner: return "300–450"
        case .intermediate: return "450–575"
        case .advanced: return "575–700"
        case .pro: return "700+"
        }
    }

    var defaultFargo: Int {
        switch self {
        case .novice: return 200
        case .beginner: return 375
        case .intermediate: return 500
        case .advanced: return 625
        case .pro: return 750
        }
    }
}

enum DedicationLevel: Int, Codable, CaseIterable, Identifiable {
    case justForFun = 1
    case maybe
    case neutral
    case yes
    case veryMuch

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .justForFun: return NSLocalizedString("Just for fun", comment: "")
        case .maybe: return NSLocalizedString("Light commitment", comment: "")
        case .neutral: return NSLocalizedString("Balanced commitment", comment: "")
        case .yes: return NSLocalizedString("High commitment", comment: "")
        case .veryMuch: return NSLocalizedString("Tournament mode", comment: "")
        }
    }
}

enum PrimaryGame: String, Codable, CaseIterable, Identifiable {
    case eightBall
    case nineBall
    case both

    var id: String { rawValue }

    var label: String {
        switch self {
        case .eightBall: return "8-ball"
        case .nineBall: return "9-ball"
        case .both: return NSLocalizedString("Both", comment: "")
        }
    }
}

enum FrequencyBand: String, Codable, CaseIterable, Identifiable {
    case oneToTwo
    case threeToFour
    case fivePlus

    var id: String { rawValue }

    var label: String {
        switch self {
        case .oneToTwo: return "1–2 / week"
        case .threeToFour: return "3–4 / week"
        case .fivePlus: return "5+ / week"
        }
    }

    var frequency: String {
        switch self {
        case .oneToTwo: return "1–2"
        case .threeToFour: return "3–4"
        case .fivePlus: return "5+"
        }
    }

    var sublabel: String {
        switch self {
        case .oneToTwo: return NSLocalizedString("Casual", comment: "")
        case .threeToFour: return NSLocalizedString("Regular", comment: "")
        case .fivePlus: return NSLocalizedString("Dedicated", comment: "")
        }
    }
}

struct PlayerProfile: Codable, Equatable {
    var hasCompletedOnboarding: Bool = false
    var hasSeenLegacyPrompt: Bool = false
    var skillLevel: SkillLevel = .intermediate
    var baselineFargo: Int = 400
    var dedication: DedicationLevel = .neutral
    var primaryGame: PrimaryGame = .eightBall
    var weeklyFrequencyBand: FrequencyBand = .oneToTwo
    var nickname: String = ""

    var clampedBaseline: Int {
        min(max(baselineFargo, 0), 850)
    }

    var displayName: String {
        let trimmed = nickname.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? NSLocalizedString("Me", comment: "") : trimmed
    }
}

@MainActor
final class PlayerProfileStore: ObservableObject {
    @Published var profile: PlayerProfile = PlayerProfile()
    @Published var rerunToken: Int = 0

    private let key = "poolstats.player.profile.v1"

    init() {
        load()
    }

    func completeOnboarding(_ updated: PlayerProfile) {
        var next = updated
        next.hasCompletedOnboarding = true
        next.hasSeenLegacyPrompt = true
        next.baselineFargo = min(max(next.baselineFargo, 0), 850)
        profile = next
        save()
    }

    func skipOnboarding() {
        profile.hasCompletedOnboarding = true
        profile.hasSeenLegacyPrompt = true
        profile.baselineFargo = profile.skillLevel.defaultFargo
        save()
    }

    func markLegacyPromptSeen() {
        guard profile.hasSeenLegacyPrompt == false else { return }
        profile.hasSeenLegacyPrompt = true
        save()
    }

    func updateProfile(_ mutate: (inout PlayerProfile) -> Void) {
        var next = profile
        mutate(&next)
        next.baselineFargo = min(max(next.baselineFargo, 0), 850)
        profile = next
        save()
    }

    func requestRerunOnboarding() {
        rerunToken += 1
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(PlayerProfile.self, from: data) else { return }
        profile = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

extension GoalsStore {
    func starterGoals(from profile: PlayerProfile) -> [Goal] {
        let intensity = Double(profile.dedication.rawValue - 1) / 4.0
        let freqFactor: Double
        switch profile.weeklyFrequencyBand {
        case .oneToTwo: freqFactor = 0.85
        case .threeToFour: freqFactor = 1.0
        case .fivePlus: freqFactor = 1.15
        }
        let effort = max(0.55, intensity * freqFactor)

        let now = Date()
        let year = Calendar.current.component(.year, from: now)
        let yearEnd = Calendar.current.date(from: DateComponents(year: year, month: 12, day: 31)) ?? now

        let matchScope: GoalSessionScope = .match
        let practiceScope: GoalSessionScope = .practice
        let sessionScope: GoalSessionScope = profile.primaryGame == .both ? .all : .match

        let conversionTarget = min(85.0, max(35.0, 42.0 + effort * 25.0))
        let matchWinTarget = min(85.0, max(45.0, 50.0 + effort * 20.0))
        let runoutTarget = max(20.0, round(35.0 + effort * 70.0))
        let missTarget = max(2.0, round((10.0 - effort * 4.0) * 10) / 10.0)
        let positionalTarget = max(2.0, round((9.0 - effort * 3.5) * 10) / 10.0)
        let perfTarget = max(6.0, round((6.5 + effort * 2.2) * 10) / 10.0)

        let rollingSessions = max(8, Int(round(10 + effort * 20)))
        let rollingRacks = max(60, Int(round(70 + effort * 110)))

        return [
            Goal(title: AppLanguageRuntime.localizedFormat("Open layouts to %lld%%", Int(round(conversionTarget))),
                 metric: .conversionRate,
                 target: conversionTarget,
                 window: .rolling(.init(amount: rollingSessions, unit: .sessions)),
                 sessionScope: matchScope,
                 starterGenerated: true),

            Goal(title: AppLanguageRuntime.localizedFormat("Match win rate above %lld%%", Int(round(matchWinTarget))),
                 metric: .matchWinRate,
                 target: matchWinTarget,
                 window: .rolling(.init(amount: max(8, rollingSessions / 2), unit: .sessions)),
                 sessionScope: matchScope,
                 starterGenerated: true),

            Goal(title: AppLanguageRuntime.localizedFormat("Record %lld runouts by year end", Int(runoutTarget)),
                 metric: .runouts,
                 target: runoutTarget,
                 window: .dueDate(yearEnd),
                 valueStyle: .cumulative,
                 sessionScope: sessionScope,
                 starterGenerated: true),

            Goal(title: AppLanguageRuntime.localizedFormat("Keep miss errors under %.1f per rack", missTarget),
                 metric: .missErrors,
                 target: missTarget,
                 window: .rolling(.init(amount: rollingRacks, unit: .racks)),
                 valueStyle: .average,
                 averageBasis: .racks,
                 sessionScope: practiceScope,
                 starterGenerated: true),

            Goal(title: AppLanguageRuntime.localizedFormat("Keep positional errors under %.1f per rack", positionalTarget),
                 metric: .positionalErrors,
                 target: positionalTarget,
                 window: .rolling(.init(amount: rollingRacks, unit: .racks)),
                 valueStyle: .average,
                 averageBasis: .racks,
                 sessionScope: practiceScope,
                 starterGenerated: true),

            Goal(title: AppLanguageRuntime.localizedFormat("Average performance %.1f+", perfTarget),
                 metric: .averagePerformance,
                 target: perfTarget,
                 window: .rolling(.init(amount: rollingSessions, unit: .sessions)),
                 sessionScope: .all,
                 starterGenerated: true)
        ]
    }
}
