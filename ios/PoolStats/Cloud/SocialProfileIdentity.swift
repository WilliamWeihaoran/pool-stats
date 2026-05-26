import Foundation

enum SocialProfileIdentity {
    static let hiddenPlayerName = NSLocalizedString("Hidden player", comment: "")

    private static let objectionableTerms = [
        "asshole",
        "bitch",
        "chink",
        "cunt",
        "faggot",
        "fuck",
        "kike",
        "nigger",
        "shit",
        "slut",
        "spic",
        "whore",
    ]

    private static let leetspeakMap: [Character: Character] = [
        "@": "a",
        "$": "s",
        "0": "o",
        "1": "i",
        "3": "e",
        "4": "a",
        "5": "s",
        "7": "t",
    ]

    static func normalizeFriendCode(_ raw: String) -> String {
        let compact = raw.uppercased().filter { $0.isLetter || $0.isNumber }
        let body = compact.hasPrefix("PS") ? String(compact.dropFirst(2)) : compact
        guard body.count >= 6 else {
            return raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        }
        let prefix = body.prefix(3)
        let suffix = body.dropFirst(3).prefix(3)
        return "PS-\(prefix)-\(suffix)"
    }

    static func isValidFriendCode(_ raw: String) -> Bool {
        let normalized = normalizeFriendCode(raw)
        let compact = normalized.uppercased().filter { $0.isLetter || $0.isNumber }
        guard compact.hasPrefix("PS") else { return false }
        return compact.dropFirst(2).count == 6
    }

    static func isAllowedPublicDisplayName(_ raw: String) -> Bool {
        let normalized = normalizedModerationText(raw)
        guard !normalized.isEmpty else { return false }
        return !objectionableTerms.contains(where: { normalized.contains($0) })
    }

    static func presentableDisplayName(_ raw: String) -> String {
        isAllowedPublicDisplayName(raw) ? raw : hiddenPlayerName
    }

    static func generateFriendCode() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        let first = String((0..<3).map { _ in alphabet.randomElement()! })
        let second = String((0..<3).map { _ in alphabet.randomElement()! })
        return "PS-\(first)-\(second)"
    }

    static func mailtoURL(email: String, subject: String, body: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body),
        ]
        return components.url
    }

    private static func normalizedModerationText(_ raw: String) -> String {
        let mapped = raw
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .map { leetspeakMap[$0] ?? $0 }
        return String(mapped.filter { $0.isLetter })
    }
}
