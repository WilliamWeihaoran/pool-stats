import Foundation

enum WatchSyncReconciler {
    static let localCloseSuppressionWindow: TimeInterval = 10 * 60

    static func normalizedIdentifier(_ identifier: String?) -> String? {
        guard let identifier else { return nil }
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func isSessionClearMessage(_ message: String?) -> Bool {
        switch message {
        case "session_cleared", "session_ended", "session_discarded", "drill_session_ended":
            return true
        default:
            return false
        }
    }

    static func displayedBreakerValue(_ selectedBreaker: String?) -> String {
        normalizedIdentifier(selectedBreaker) == "opp" ? "opp" : "me"
    }

    static func shouldClearLocalSession(
        activeSessionUUID: String?,
        clearedSessionUUID: String?,
        message: String?
    ) -> Bool {
        let activeSessionUUID = normalizedIdentifier(activeSessionUUID)
        if clearedSessionUUID != nil, normalizedIdentifier(clearedSessionUUID) == nil {
            return false
        }
        if let clearedSessionUUID = normalizedIdentifier(clearedSessionUUID) {
            return activeSessionUUID == clearedSessionUUID
        }
        return isSessionClearMessage(message)
    }

    static func shouldPreserveRecentlyEndedComplication(
        activeSessionUUID: String?,
        message: String?,
        clearedSessionUUID: String?,
        complicationSessionUUID: String?,
        recentlyEndedAt: Date?
    ) -> Bool {
        let activeSessionUUID = normalizedIdentifier(activeSessionUUID)
        guard activeSessionUUID == nil,
              message == "session_ended",
              let clearedSessionUUID = normalizedIdentifier(clearedSessionUUID),
              recentlyEndedAt != nil else {
            return false
        }
        return normalizedIdentifier(complicationSessionUUID) == clearedSessionUUID
    }

    static func shouldClearIdleComplication(
        hasActiveSession: Bool,
        recentlyEndedAt: Date?,
        complicationSessionUUID: String?,
        snapshotClearedSessionUUID: String?,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard !hasActiveSession else { return true }
        guard let recentlyEndedAt else { return true }
        guard calendar.isDate(recentlyEndedAt, inSameDayAs: now) else { return true }
        if let snapshotClearedSessionUUID = normalizedIdentifier(snapshotClearedSessionUUID) {
            return normalizedIdentifier(complicationSessionUUID) != snapshotClearedSessionUUID
        }
        return false
    }

    static func shouldShowRecentScore(
        hasActiveSession: Bool,
        updatedAt: Date,
        recentlyEndedAt: Date?,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard !hasActiveSession, recentlyEndedAt != nil else { return false }
        return calendar.isDate(updatedAt, inSameDayAs: now)
    }

    static func shouldSuppressActiveSnapshotAfterLocalClose(
        remoteSessionUUID: String?,
        locallyClosedSessionUUID: String?,
        locallyClosedAt: Date?,
        now: Date = Date(),
        suppressionWindow: TimeInterval = localCloseSuppressionWindow
    ) -> Bool {
        guard let remoteSessionUUID = normalizedIdentifier(remoteSessionUUID),
              let locallyClosedSessionUUID = normalizedIdentifier(locallyClosedSessionUUID),
              remoteSessionUUID == locallyClosedSessionUUID,
              let locallyClosedAt else {
            return false
        }
        return abs(now.timeIntervalSince(locallyClosedAt)) <= suppressionWindow
    }

    static func acceptsSessionScopedEnvelope(
        currentSessionUUID: String?,
        envelopeSessionUUID: String?
    ) -> Bool {
        let currentSessionUUID = normalizedIdentifier(currentSessionUUID)
        if envelopeSessionUUID != nil, normalizedIdentifier(envelopeSessionUUID) == nil {
            return false
        }
        guard let envelopeSessionUUID = normalizedIdentifier(envelopeSessionUUID) else {
            return currentSessionUUID != nil
        }
        return currentSessionUUID == envelopeSessionUUID
    }

    static func acceptsRackScopedEnvelope(
        currentSessionUUID: String?,
        currentRackUUID: String?,
        envelopeSessionUUID: String?,
        envelopeRackUUID: String?
    ) -> Bool {
        guard acceptsSessionScopedEnvelope(
            currentSessionUUID: currentSessionUUID,
            envelopeSessionUUID: envelopeSessionUUID
        ) else {
            return false
        }
        let currentRackUUID = normalizedIdentifier(currentRackUUID)
        if envelopeRackUUID != nil, normalizedIdentifier(envelopeRackUUID) == nil {
            return false
        }
        guard let envelopeRackUUID = normalizedIdentifier(envelopeRackUUID) else {
            return currentRackUUID != nil
        }
        return currentRackUUID == envelopeRackUUID
    }
}
