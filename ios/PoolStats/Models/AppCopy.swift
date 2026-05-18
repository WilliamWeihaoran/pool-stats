import Foundation

enum AppCopyTone {
    case accent
    case success
    case warning
    case danger
    case muted
}

enum LogStartCopy {
    static func headerTitle(mode: String) -> String {
        mode == "practice"
            ? NSLocalizedString("Start practice", comment: "")
            : NSLocalizedString("Log a match", comment: "")
    }

    static func startButtonTitle(mode: String) -> String {
        mode == "practice"
            ? NSLocalizedString("Start practice", comment: "")
            : NSLocalizedString("Start session", comment: "")
    }

    static func matchSummary(
        gameText: String,
        raceToEnabled: Bool,
        raceTo: Int,
        opponent: String,
        dateSummary: String
    ) -> String {
        let raceText = raceToEnabled ? AppLanguageRuntime.localizedFormat("Race to %lld", raceTo) : nil
        let versusText = opponent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? nil
            : AppLanguageRuntime.localizedFormat("vs %@", opponent)
        let segments = [
            NSLocalizedString("Match", comment: ""),
            gameText,
            raceText,
            versusText,
            dateSummary
        ]
        return segments.compactMap { $0 }.joined(separator: " · ")
    }

    static func practiceSummary(templateTitle: String?, difficultySummary: String, targetSummary: String) -> String {
        guard let templateTitle, !templateTitle.isEmpty else {
            return NSLocalizedString("Choose a drill", comment: "")
        }
        return [templateTitle, difficultySummary, targetSummary].joined(separator: " · ")
    }

    static func advancedSummary(noteIsSet: Bool, raceToEnabled: Bool, raceTo: Int) -> String? {
        let noteSet = noteIsSet ? NSLocalizedString("Note", comment: "") : nil
        let raceSet = raceToEnabled ? AppLanguageRuntime.localizedFormat("Race %lld", raceTo) : nil
        let summary = [noteSet, raceSet].compactMap { $0 }.joined(separator: " · ")
        return summary.isEmpty ? nil : summary
    }
}

enum HistoryCopy {
    static func deleteAlertTitle(count: Int) -> String {
        count == 1
            ? NSLocalizedString("Delete session?", comment: "")
            : NSLocalizedString("Delete selected sessions?", comment: "")
    }

    static func deleteAlertMessage(count: Int) -> String {
        if count == 1 {
            return NSLocalizedString("This session will be removed from History.", comment: "")
        }
        return AppLanguageRuntime.localizedFormat("%lld sessions will be removed from History.", count)
    }

    static func historySummary(visibleCount: Int, syncSubtitle: String) -> String {
        AppLanguageRuntime.localizedFormat("%lld sessions currently visible. %@", visibleCount, syncSubtitle)
    }

    static func selectionSummary(count: Int) -> String {
        if count == 0 {
            return NSLocalizedString("Tap sessions to select them for deletion.", comment: "")
        }
        if count == 1 {
            return NSLocalizedString("1 session selected. Deleting removes it from History.", comment: "")
        }
        return AppLanguageRuntime.localizedFormat("%lld sessions selected. Deleting removes them from History.", count)
    }

    static func deleteActionLabel(selectedCount: Int) -> String {
        selectedCount == 0
            ? NSLocalizedString("Delete", comment: "")
            : AppLanguageRuntime.localizedFormat("Delete %lld", selectedCount)
    }
}

struct ShareHintCopy {
    let title: String
    let message: String
}

struct SummarySharePresentation {
    let statusLabel: String
    let statusTone: AppCopyTone
    let buttonTitle: String
    let buttonTone: AppCopyTone
    let message: String?
    let messageTone: AppCopyTone
}

struct SummaryMatchShareState {
    let sessionUUID: String
    let friendCode: String
    let friendDisplayName: String
    let latestShare: OutgoingMatchShare?
    let matchShareState: SocialProfileStore.MatchShareState
    let refreshState: SocialProfileStore.OutgoingShareRefreshState

    var isSendingCurrentFriend: Bool {
        if case .sending(let code) = matchShareState {
            return code == friendCode
        }
        return false
    }

    var isRefreshingCurrentSession: Bool {
        if case .loading(let refreshingSessionUUID) = refreshState {
            return refreshingSessionUUID == nil || refreshingSessionUUID == sessionUUID
        }
        return false
    }

    var isActionDisabled: Bool {
        if let latestShare, latestShare.isPending { return true }
        if let latestShare, latestShare.isAccepted { return true }
        return isSendingCurrentFriend || isRefreshingCurrentSession
    }

    var presentation: SummarySharePresentation {
        let runtimeFailureMessage = SummaryCopy.runtimeShareFailureMessage(
            matchShareState: matchShareState,
            refreshState: refreshState
        )

        let statusLabel: String
        let statusTone: AppCopyTone
        if let latestShare, latestShare.isPending {
            statusLabel = NSLocalizedString("Pending acceptance", comment: "")
            statusTone = .warning
        } else if let latestShare, latestShare.isAccepted {
            statusLabel = NSLocalizedString("Accepted", comment: "")
            statusTone = .success
        } else if let latestShare, latestShare.isDeclined {
            statusLabel = NSLocalizedString("Declined", comment: "")
            statusTone = .danger
        } else if let latestShare, latestShare.isFailed {
            statusLabel = NSLocalizedString("Failed", comment: "")
            statusTone = .danger
        } else {
            statusLabel = NSLocalizedString("Ready to share", comment: "")
            statusTone = .accent
        }

        let buttonTitle: String
        let buttonTone: AppCopyTone
        if let latestShare, latestShare.isPending {
            buttonTitle = NSLocalizedString("Shared with friend", comment: "")
            buttonTone = .muted
        } else if let latestShare, latestShare.isAccepted {
            buttonTitle = NSLocalizedString("Shared and accepted", comment: "")
            buttonTone = .success
        } else if let latestShare, latestShare.isDeclined {
            buttonTitle = NSLocalizedString("Share again", comment: "")
            buttonTone = .warning
        } else if let latestShare, latestShare.isFailed {
            buttonTitle = NSLocalizedString("Try sharing again", comment: "")
            buttonTone = .warning
        } else {
            buttonTitle = AppLanguageRuntime.localizedFormat("Share with %@", friendDisplayName)
            buttonTone = .accent
        }

        let message: String?
        let messageTone: AppCopyTone
        if let runtimeFailureMessage {
            message = runtimeFailureMessage
            messageTone = .danger
        } else if let latestShare, latestShare.isPending {
            message = AppLanguageRuntime.localizedFormat("%@ can accept this in Settings > Me.", friendDisplayName)
            messageTone = .muted
        } else if let latestShare, latestShare.isAccepted {
            let acceptedText = latestShare.acceptedAt.map {
                AppLanguageRuntime.localizedFormat(" on %@", AppFormatters.sessionDate($0))
            } ?? ""
            message = AppLanguageRuntime.localizedFormat(
                "%@ accepted this match into their history%@.",
                friendDisplayName,
                acceptedText
            )
            messageTone = .muted
        } else if let latestShare, latestShare.isDeclined {
            message = AppLanguageRuntime.localizedFormat(
                "%@ declined this shared match. You can share it again if needed.",
                friendDisplayName
            )
            messageTone = .muted
        } else if let latestShare, latestShare.isFailed {
            message = latestShare.failureMessage ?? NSLocalizedString("Could not share this match.", comment: "")
            messageTone = .danger
        } else {
            message = NSLocalizedString("Send a match invite your friend can accept into their history.", comment: "")
            messageTone = .muted
        }

        return SummarySharePresentation(
            statusLabel: statusLabel,
            statusTone: statusTone,
            buttonTitle: buttonTitle,
            buttonTone: buttonTone,
            message: message,
            messageTone: messageTone
        )
    }
}

enum SummaryCopy {
    static var opponentPlaceholder: String {
        NSLocalizedString("Optional", comment: "")
    }

    static var shareProfileHint: ShareHintCopy {
        ShareHintCopy(
            title: NSLocalizedString("Create your public profile first", comment: ""),
            message: NSLocalizedString(
                "Create a public profile in Settings > Me, then send this match to a saved friend.",
                comment: ""
            )
        )
    }

    static var shareNoFriendsHint: ShareHintCopy {
        ShareHintCopy(
            title: NSLocalizedString("No friends yet", comment: ""),
            message: NSLocalizedString(
                "Add a friend by code in Settings > Me, then come back here to share this match.",
                comment: ""
            )
        )
    }

    static func runtimeShareFailureMessage(
        matchShareState: SocialProfileStore.MatchShareState,
        refreshState: SocialProfileStore.OutgoingShareRefreshState
    ) -> String? {
        if case .failed(let message) = matchShareState { return message }
        if case .failed(let message) = refreshState { return message }
        return nil
    }

    static func drillAverageLabel(countUnit: DrillCountUnit?) -> String {
        countUnit == .balls
            ? NSLocalizedString("Avg potted", comment: "")
            : NSLocalizedString("Avg completed", comment: "")
    }

    static func drillProgressText(made: Int, target: Int) -> String {
        AppLanguageRuntime.localizedFormat("%lld/%lld potted", made, target)
    }

    static func rackErrorsText(_ count: Int) -> String {
        AppLanguageRuntime.localizedFormat("%lld UE", count)
    }

    static func attemptsText(_ count: Int) -> String {
        AppLanguageRuntime.localizedFormat("%lld attempts", count)
    }

    static func racksText(_ count: Int) -> String {
        AppLanguageRuntime.localizedFormat("%lld racks", count)
    }

    static func metaText(for session: Session) -> String {
        let opponent = session.isPractice ? "" : session.opponent.trimmingCharacters(in: .whitespaces)
        let opponentText = opponent.isEmpty ? nil : AppLanguageRuntime.localizedFormat("vs %@", opponent)
        let countText = session.isDrillPractice ? attemptsText(session.drillAttempts) : racksText(session.racks.count)
        return [
            session.typeLabel,
            session.isDrillPractice ? session.drillTitle : session.gameLabel,
            session.raceLabel,
            opponentText,
            countText,
            session.drillTargetLabel,
            AppFormatters.sessionDate(session.ts)
        ]
        .compactMap { $0 }
        .joined(separator: " · ")
    }

    static func outcomeLabel(_ outcome: String?) -> String {
        switch outcome {
        case "runout":
            return NSLocalizedString("Runout", comment: "")
        case "noRunout":
            return NSLocalizedString("No runout", comment: "")
        case "safety":
            return NSLocalizedString("Safety", comment: "")
        case "error":
            return NSLocalizedString("Error", comment: "")
        case "other":
            return NSLocalizedString("Other", comment: "")
        default:
            return "—"
        }
    }

    static func rackResultLabel(isPractice: Bool, result: String?) -> String {
        if isPractice {
            return NSLocalizedString("Practice", comment: "")
        }
        return result == "won"
            ? NSLocalizedString("Won", comment: "")
            : NSLocalizedString("Lost", comment: "")
    }
}

struct DashboardRecentFormPresentation {
    let subtitle: String
    let recordText: String
    let emptyStateMessage: String?
    let legendTitle: String
    let legendValue: String
}

enum DashboardCopy {
    static var fargoInfoTitle: String {
        NSLocalizedString("Fargo Estimate", comment: "")
    }

    static var fargoInfoButton: String {
        NSLocalizedString("Got it", comment: "")
    }

    static var fargoInfoMessage: String {
        NSLocalizedString(
            "Fargo is a skill rating system for pool players. This visual blends your baseline Fargo with tracked match performance, then scores five areas: potting, position, pattern, runout, and overall.",
            comment: ""
        )
    }

    static func importReplaceMessage(_ count: Int) -> String {
        AppLanguageRuntime.localizedFormat("Replace all data with %lld sessions?", count)
    }

    static func activeDays(_ count: Int) -> String {
        AppLanguageRuntime.localizedFormat("%lld active days", count)
    }

    static func recentFormPresentation(recentCount: Int, wins: Int, draws: Int, losses: Int) -> DashboardRecentFormPresentation {
        if recentCount == 0 {
            return DashboardRecentFormPresentation(
                subtitle: NSLocalizedString("No match results in current filters", comment: ""),
                recordText: NSLocalizedString("No matches yet", comment: ""),
                emptyStateMessage: NSLocalizedString("Log a few matches and your form will appear here.", comment: ""),
                legendTitle: NSLocalizedString("Outcome mix", comment: ""),
                legendValue: NSLocalizedString("Wins · Draws · Losses", comment: "")
            )
        }

        return DashboardRecentFormPresentation(
            subtitle: AppLanguageRuntime.localizedFormat("Last %lld match results", recentCount),
            recordText: AppLanguageRuntime.localizedFormat("%lldW %lldD %lldL", wins, draws, losses),
            emptyStateMessage: nil,
            legendTitle: NSLocalizedString("Outcome mix", comment: ""),
            legendValue: NSLocalizedString("Wins · Draws · Losses", comment: "")
        )
    }

    static var layoutLabels: [String] {
        [
            NSLocalizedString("Open", comment: ""),
            NSLocalizedString("Clustered", comment: ""),
            NSLocalizedString("Problematic", comment: ""),
            NSLocalizedString("Snookered", comment: "")
        ]
    }
}
