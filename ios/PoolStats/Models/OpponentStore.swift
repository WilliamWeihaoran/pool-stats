import Foundation

struct OpponentProfile: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var displayName: String
    var aliases: [String] = []
    var isFavorite: Bool = false
    var createdAt: Date = Date()
    var lastSeenAt: Date = Date()

    var allNames: [String] {
        Array(Set([displayName] + aliases)).sorted()
    }
}

struct OpponentHeadToHead: Hashable {
    let sessions: Int
    let sessionWins: Int
    let sessionLosses: Int
    let rackWins: Int
    let rackLosses: Int
    let averageRating: String
    let lastPlayed: String

    var sessionWinRate: String {
        guard sessions > 0 else { return "—" }
        let pct = Int(round(Double(sessionWins) / Double(sessions) * 100))
        return "\(pct)%"
    }

    var rackWinRate: String {
        let total = rackWins + rackLosses
        guard total > 0 else { return "—" }
        let pct = Int(round(Double(rackWins) / Double(total) * 100))
        return "\(pct)%"
    }
}

@MainActor
final class OpponentStore: ObservableObject {
    @Published var profiles: [OpponentProfile] = []

    private let localURL: URL
    private let storageKey = "poolstats.opponents.v1"

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("PoolStats", isDirectory: true)
        localURL = dir.appendingPathComponent("opponents.json")
        loadLocal()
    }

    func sync(with sessions: [Session]) {
        let entries = sessions.compactMap { session -> (key: String, display: String, ts: Date)? in
            let cleaned = session.opponent.trimmingCharacters(in: .whitespacesAndNewlines)
            guard cleaned.isEmpty == false else { return nil }
            return (Self.normalize(cleaned), cleaned, session.ts)
        }

        guard entries.isEmpty == false else { return }

        let grouped = Dictionary(grouping: entries, by: { $0.key })
        var changed = false

        for (key, values) in grouped {
            let latest = values.max(by: { $0.ts < $1.ts })?.ts ?? Date()
            let displayName = values.first?.display ?? key

            if let idx = profiles.firstIndex(where: { Self.nameMatches($0, key) }) {
                if profiles[idx].lastSeenAt < latest {
                    profiles[idx].lastSeenAt = latest
                    changed = true
                }
                if Self.normalize(profiles[idx].displayName) != Self.normalize(displayName) {
                    profiles[idx].displayName = displayName
                    changed = true
                }
            } else {
                profiles.append(OpponentProfile(displayName: displayName, lastSeenAt: latest))
                changed = true
            }
        }

        sortProfiles()

        if changed { saveLocal() }
    }

    func opponentNames(from sessions: [Session]) -> [String] {
        let raw = sessions.compactMap { session -> String? in
            let cleaned = session.opponent.trimmingCharacters(in: .whitespacesAndNewlines)
            return cleaned.isEmpty ? nil : cleaned
        }

        let known = Set(profiles.flatMap { [$0.displayName] + $0.aliases }.map(Self.normalize))
        let candidates = profiles.map(\.displayName) + raw.filter { known.contains(Self.normalize($0)) == false }
        var seen = Set<String>()
        var ordered: [String] = []
        for name in candidates {
            let key = Self.normalize(name)
            guard key.isEmpty == false, seen.insert(key).inserted else { continue }
            ordered.append(name)
        }

        let favorites = Set(profiles.filter(\.isFavorite).flatMap { $0.allNames.map(Self.normalize) })
        ordered.sort { lhs, rhs in
            let lhsFav = favorites.contains(Self.normalize(lhs))
            let rhsFav = favorites.contains(Self.normalize(rhs))
            if lhsFav != rhsFav { return lhsFav && !rhsFav }
            return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
        }
        return ordered
    }

    func addOpponent(name: String) {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.isEmpty == false else { return }
        if let idx = profiles.firstIndex(where: { Self.nameMatches($0, cleaned) }) {
            profiles[idx].displayName = cleaned
            profiles[idx].aliases.removeAll { Self.normalize($0) == Self.normalize(cleaned) }
            profiles[idx].lastSeenAt = Date()
        } else {
            profiles.insert(OpponentProfile(displayName: cleaned), at: 0)
        }
        sortProfiles()
        saveLocal()
    }

    func updateOpponent(id: UUID, displayName: String) {
        let cleaned = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.isEmpty == false else { return }
        guard let idx = profiles.firstIndex(where: { $0.id == id }) else { return }
        let old = profiles[idx].displayName
        if Self.normalize(old) != Self.normalize(cleaned) {
            if profiles[idx].aliases.contains(where: { Self.normalize($0) == Self.normalize(old) }) == false {
                profiles[idx].aliases.append(old)
            }
            profiles[idx].displayName = cleaned
        }
        profiles[idx].lastSeenAt = Date()
        sortProfiles()
        saveLocal()
    }

    func deleteOpponent(id: UUID) {
        profiles.removeAll { $0.id == id }
        sortProfiles()
        saveLocal()
    }

    func toggleFavorite(id: UUID) {
        guard let idx = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles[idx].isFavorite.toggle()
        sortProfiles()
        saveLocal()
    }

    func availableNames(from sessions: [Session]) -> [String] {
        let unique = opponentNames(from: sessions)
        return unique.isEmpty ? ["All opponents"] : ["All opponents"] + unique
    }

    func profile(for name: String) -> OpponentProfile? {
        let cleaned = Self.normalize(name)
        return profiles.first { Self.nameMatches($0, cleaned) }
    }

    func matches(_ sessionOpponent: String, selected selectedName: String) -> Bool {
        let selected = Self.normalize(selectedName)
        guard selected.isEmpty == false, selected != Self.normalize("All opponents") else { return true }
        let cleaned = Self.normalize(sessionOpponent)
        guard cleaned.isEmpty == false else { return false }
        if cleaned == selected { return true }
        guard let profile = profile(for: selectedName) else { return false }
        return Self.nameMatches(profile, cleaned)
    }

    func headToHead(for name: String, sessions: [Session]) -> OpponentHeadToHead {
        let cleaned = Self.normalize(name)
        let relatedProfiles = profiles.filter { Self.nameMatches($0, cleaned) }
        let names = Set(relatedProfiles.flatMap { $0.allNames }.map(Self.normalize) + [cleaned])

        let matches = sessions.filter { names.contains(Self.normalize($0.opponent)) && $0.type == "match" }
        let wins = matches.filter { $0.wins > $0.racks.count / 2 }.count
        let losses = matches.count - wins
        let rackWins = matches.reduce(0) { $0 + $1.wins }
        let rackLosses = matches.reduce(0) { $0 + $1.losses }
        let ratings = matches.compactMap { $0.performanceRating }
        let avgRating = ratings.isEmpty ? "—" : String(format: "%.1f/10", Double(ratings.reduce(0, +)) / Double(ratings.count))
        let last = sessions
            .filter { names.contains(Self.normalize($0.opponent)) }
            .max(by: { $0.ts < $1.ts })
            .map { AppFormatters.sessionDate($0.ts) } ?? "—"

        return OpponentHeadToHead(
            sessions: matches.count,
            sessionWins: wins,
            sessionLosses: losses,
            rackWins: rackWins,
            rackLosses: rackLosses,
            averageRating: avgRating,
            lastPlayed: last
        )
    }

    func favoriteOpponent(from sessions: [Session]) -> String {
        if let firstFav = profiles.first(where: { $0.isFavorite })?.displayName {
            return firstFav
        }
        let names = sessions
            .map { $0.opponent.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !names.isEmpty else { return "—" }
        let counts = Dictionary(grouping: names, by: { Self.normalize($0) }).mapValues { values in
            (count: values.count, display: values.first ?? "—")
        }
        guard let top = counts.max(by: { $0.value < $1.value }) else { return "—" }
        return top.value.display
    }

    private func updateLastSeen(for name: String, at date: Date) {
        guard let idx = profiles.firstIndex(where: { Self.nameMatches($0, name) }) else { return }
        if profiles[idx].lastSeenAt < date {
            profiles[idx].lastSeenAt = date
            saveLocal()
        }
    }

    private func containsName(_ name: String) -> Bool {
        profiles.contains { Self.nameMatches($0, name) }
    }

    private func sortProfiles() {
        profiles.sort { lhs, rhs in
            if lhs.isFavorite != rhs.isFavorite { return lhs.isFavorite && !rhs.isFavorite }
            if lhs.lastSeenAt != rhs.lastSeenAt { return lhs.lastSeenAt > rhs.lastSeenAt }
            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }

    private func loadLocal() {
        guard let data = try? Data(contentsOf: localURL) else { return }
        if let loaded = try? JSONDecoder().decode([OpponentProfile].self, from: data) {
            profiles = loaded
        }
    }

    private func saveLocal() {
        guard let data = try? makeEncoder().encode(profiles) else { return }
        let dir = localURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: localURL, options: .atomic)
        UserDefaults.standard.set(true, forKey: storageKey)
    }

    private static func normalize(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func nameMatches(_ profile: OpponentProfile, _ name: String) -> Bool {
        let cleaned = normalize(name)
        return normalize(profile.displayName) == cleaned || profile.aliases.contains(where: { normalize($0) == cleaned })
    }

    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
