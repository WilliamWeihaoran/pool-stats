import SwiftUI
import UIKit

struct SummaryView: View {
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var opponentStore: OpponentStore
    @EnvironmentObject private var socialProfileStore: SocialProfileStore
    @Environment(\.horizontalSizeClass) private var hSizeClass

    let session: Session
    var completionButtonTitle: String? = nil
    var onCompletion: (() -> Void)? = nil

    @State private var labelText: String = ""
    @State private var opponentText: String = ""
    @State private var performanceRating: Int? = nil
    @State private var performanceValue: Int = 5
    @State private var selectedFriendCode: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                summaryNavigationRow
                header
                timeSection
                performanceSection
                if shouldShowMatchShare {
                    SummaryMatchShareSection(session: session, selectedFriendCode: $selectedFriendCode)
                }
                if session.isDrillPractice {
                    drillSummaryCards
                    drillAttemptLogSection
                } else {
                    summaryCards
                    errorsSection
                    breaksSection
                    rackLogSection
                }
                completionSection
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .padding(.bottom, bottomContentPadding)
        }
        .background(Theme.bg)
        .navigationTitle("Summary")
        .toolbar(.hidden, for: .navigationBar)
        .appBackSwipeEnabled()
        .onAppear {
            labelText = session.label
            opponentText = session.opponent
            performanceRating = session.performanceRating
            performanceValue = session.performanceRating ?? 5
            if selectedFriendCode.isEmpty {
                selectedFriendCode = socialProfileStore.friends.first?.friendCode ?? ""
            }
        }
        .task(id: selectedFriendCode) {
            guard shouldShowMatchShare, socialProfileStore.profile != nil else { return }
            await socialProfileStore.refreshOutgoingShares(for: session.sessionUUID)
        }
    }

    private var bottomContentPadding: CGFloat {
        onCompletion == nil ? 78 : 96
    }

    @ViewBuilder
    private var summaryNavigationRow: some View {
        if let completionButtonTitle, onCompletion != nil {
            HStack(spacing: 10) {
                Text("Session summary")
                    .font(.headline.weight(.bold))
                    .foregroundColor(Theme.text)
                Spacer(minLength: 0)
                Button {
                    finishSummary()
                } label: {
                    Text(LocalizedStringKey(completionButtonTitle))
                        .font(.caption.weight(.bold))
                        .foregroundColor(Theme.bg)
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(Theme.teal)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        } else {
            AppBackButton(label: "Back")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var completionSection: some View {
        if let completionButtonTitle, onCompletion != nil {
            Button {
                finishSummary()
            } label: {
                Text(LocalizedStringKey(completionButtonTitle))
                    .font(.headline.weight(.bold))
                    .foregroundColor(Theme.bg)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.teal)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(metaText())
                .font(.caption)
                .foregroundColor(Theme.muted)
            TextField("Add a session label…", text: $labelText, onCommit: saveLabel)
                .textFieldStyle(.roundedBorder)
            if !session.isPractice {
                opponentEditor
            }
        }
    }

    private var opponentEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Opponent")
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                Spacer(minLength: 0)
                Text(opponentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? SummaryCopy.opponentPlaceholder : opponentText.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.caption2.weight(.medium))
                    .foregroundColor(Theme.text2)
            }

            TextField("Opponent name", text: $opponentText, onCommit: saveOpponent)
                .textFieldStyle(.roundedBorder)

            if !opponentSuggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(opponentSuggestions.prefix(8), id: \.self) { name in
                            Button {
                                opponentText = name
                                saveOpponent()
                            } label: {
                                Text(name)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(Theme.text)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Theme.panel2)
                                    .cornerRadius(999)
                                    .overlay(Capsule().stroke(Theme.border, lineWidth: 0.6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var summaryCards: some View {
        let rs = session.racks
        let n = Double(max(rs.count, 1))
        let runouts = rs.filter { $0.outcome == "runout" }.count
        let errTotal = rs.reduce(0) { $0 + $1.unforcedErrorCount }

        let top: [(String, String)]
        if session.isPractice {
            top = [
                ("Racks", "\(rs.count)"),
                ("Runouts", "\(runouts)"),
                ("Err/rack", String(format: "%.1f", Double(errTotal) / n)),
                ("Rating", session.performanceRating.map { "\($0)/10" } ?? "—")
            ]
        } else {
            top = [
                ("Racks", "\(rs.count)"),
                ("Won", "\(session.wins)"),
                ("Lost", "\(session.losses)"),
                ("Win%", rs.isEmpty ? "—" : "\(Int(round(Double(session.wins) / Double(rs.count) * 100)))%")
            ]
        }

        return SectionCard(title: "Summary") {
            LazyVGrid(columns: Layout.fourColumn(), spacing: 8) {
                ForEach(top, id: \.0) { item in
                    MiniStatCard(label: item.0, value: item.1)
                }
            }
        }
    }

    private var timeSection: some View {
        let duration = session.durationSeconds.map(TimeInterval.init)
        let rawValue = duration.map(AppFormatters.elapsed) ?? "—"
        let adjustedValue = duration.map { AppFormatters.elapsed(session.bufferedSessionSeconds(totalSeconds: $0)) } ?? "—"
        let pacePct = duration.map { session.bufferedPacePercent(totalSeconds: $0) } ?? 0
        let bufferPct = session.bufferedPaceBufferPercent()
        let rackCount = max(session.racks.count, 1)
        let avgRawRack = duration.map { AppFormatters.elapsed($0 / Double(rackCount)) } ?? "—"
        let avgAdjRack = duration.map { AppFormatters.elapsed(session.bufferedAverageRackSeconds(totalSeconds: $0)) } ?? "—"

        return SectionCard(title: "Time") {
            VStack(alignment: .leading, spacing: 10) {
                LazyVGrid(columns: Layout.fourColumn(), spacing: 8) {
                    MiniStatCard(label: "Raw", value: rawValue)
                    MiniStatCard(label: "Adjusted", value: adjustedValue)
                    MiniStatCard(label: "Avg raw", value: avgRawRack)
                    MiniStatCard(label: "Avg adj", value: avgAdjRack)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Avg pace")
                            .font(.caption2)
                            .foregroundColor(Theme.muted)
                        Spacer(minLength: 0)
                        Text("subtracts 45s setup buffer per rack")
                            .font(.caption2)
                            .foregroundColor(Theme.amber)
                    }
                    BufferedPaceBar(value: pacePct, bufferColor: Theme.amber, activeColor: Theme.green, bufferPercent: bufferPct, height: 5)
                }
            }
        }
    }

    private var performanceSection: some View {
        SectionCard(title: "Performance") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("Rate your session")
                        .font(.caption)
                        .foregroundColor(Theme.text2)
                    Spacer()
                    Text(performanceRating.map { "\($0)/10" } ?? NSLocalizedString("Drag to rate", comment: ""))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(performanceRating == nil ? Theme.muted : performanceSliderColor)
                }

                VStack(spacing: 8) {
                    DiscreteRatingSlider(value: Binding(
                        get: { performanceValue },
                        set: { newValue in
                            performanceValue = newValue
                            performanceRating = newValue
                            savePerformanceRating(newValue)
                        }
                    ), range: 1...10, activeColor: performanceSliderColor)
                    HStack {
                        Text("1")
                            .font(.caption2)
                            .foregroundColor(ratingColor(for: 1, lowerBound: 1, upperBound: 10))
                        Spacer()
                        Text("10")
                            .font(.caption2)
                            .foregroundColor(ratingColor(for: 10, lowerBound: 1, upperBound: 10))
                    }
                }
            }
        }
    }

    private var performanceSliderColor: Color {
        guard performanceRating != nil else { return Theme.purple }
        return ratingColor(for: performanceValue, lowerBound: 1, upperBound: 10)
    }

    private var shouldShowMatchShare: Bool {
        !session.isPractice && !session.isDrillPractice && !session.racks.isEmpty
    }

    private func ratingColor(for value: Int, lowerBound: Int, upperBound: Int) -> Color {
        let clamped = Double(Swift.max(Swift.min(value, upperBound), lowerBound))
        let mid = Double(lowerBound + upperBound) / 2.0

        if clamped <= mid {
            let t = (clamped - Double(lowerBound)) / Swift.max(mid - Double(lowerBound), 1)
            return interpolateColor(from: .red, to: .orange, progress: t)
        } else {
            let t = (clamped - mid) / Swift.max(Double(upperBound) - mid, 1)
            return interpolateColor(from: .orange, to: .green, progress: t)
        }
    }

    private func interpolateColor(from start: UIColor, to end: UIColor, progress: Double) -> Color {
        let p = min(max(progress, 0), 1)
        let s = start.rgbaComponents
        let e = end.rgbaComponents
        let r = s.r + (e.r - s.r) * p
        let g = s.g + (e.g - s.g) * p
        let b = s.b + (e.b - s.b) * p
        let a = s.a + (e.a - s.a) * p
        return Color(red: r, green: g, blue: b, opacity: a)
    }

    private var drillSummaryCards: some View {
        let attempts = session.drillAttempts
        let successes = session.drillSuccesses
        let misses = session.drillMisses
        let rate = session.drillSuccessRate.map { "\($0)%" } ?? "--"
        let template = DrillLibrary.template(id: session.drillID)
        let totalCompleted = session.racks.reduce(0) { $0 + ($1.drillBallsMade ?? 0) }
        let avgCompleted = attempts == 0 ? "--" : AppLanguageRuntime.format("%.1f", Double(totalCompleted) / Double(attempts))
        let averageLabel = SummaryCopy.drillAverageLabel(countUnit: template?.countUnit)
        let progress = session.drillTargetProgress

        return SectionCard(title: "Practice") {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.drillTitle ?? session.displayLabel)
                        .font(.headline.weight(.bold))
                        .foregroundColor(Theme.text)
                    HStack(spacing: 8) {
                        badge(text: session.drillDifficultyLabel, color: Theme.purple)
                        if let count = session.drillBallCount {
                            badge(
                                text: template?.countText(count) ?? AppLanguageRuntime.localizedFormat("%lld reps", count),
                                color: Theme.amber
                            )
                        }
                        if let target = session.drillTargetLabel { badge(text: target, color: Theme.green) }
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(successes)")
                        .font(.system(size: 44, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundColor(Theme.green)
                    Text(":")
                        .font(.system(size: 36, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundColor(Theme.text2)
                    Text("\(misses)")
                        .font(.system(size: 44, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundColor(Theme.red)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                                Text(rate)
                            .font(.title3.bold().monospacedDigit())
                            .foregroundColor(Theme.text)
                        Text("success rate")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(Theme.muted)
                    }
                }

                if let progress {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("Target progress")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Theme.text2)
                            Spacer()
                            Text("\(progress.current)/\(progress.target)")
                                .font(.caption.weight(.bold).monospacedDigit())
                                .foregroundColor(Theme.green)
                        }
                        ProgressView(value: Double(progress.current), total: Double(max(progress.target, 1)))
                            .tint(Theme.green)
                    }
                }

                LazyVGrid(columns: Layout.fourColumn(), spacing: 8) {
                    MiniStatCard(label: "Attempts", value: "\(attempts)")
                    MiniStatCard(label: "Success", value: "\(successes)")
                    MiniStatCard(label: "Miss", value: "\(misses)")
                    MiniStatCard(label: averageLabel, value: avgCompleted)
                }
            }
        }
    }

    private var drillAttemptLogSection: some View {
        let mistakeCounts = Dictionary(grouping: session.racks.flatMap { $0.drillTags ?? [] }, by: { $0 })
            .mapValues { $0.count }
        return SectionCard(title: "Attempt log") {
            VStack(alignment: .leading, spacing: 10) {
                if !mistakeCounts.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mistakes")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Theme.muted)
                        HStack(spacing: 6) {
                            ForEach(mistakeCounts.keys.sorted(), id: \.self) { tag in
                                badge(text: "\(tag) \(mistakeCounts[tag] ?? 0)", color: Theme.teal)
                            }
                        }
                    }
                }
                VStack(spacing: 8) {
                    ForEach(session.racks) { rack in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text("\(rack.index)")
                                    .font(.caption)
                                    .foregroundColor(Theme.muted)
                                    .frame(width: 20, alignment: .leading)
                                Text(rack.drillOutcomeLabel)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(rack.drillOutcome == "success" ? Theme.green : Theme.red)
                                if let made = rack.drillBallsMade, let target = rack.drillTargetBallCount {
                                    Text(SummaryCopy.drillProgressText(made: made, target: target))
                                        .font(.caption.weight(.bold).monospacedDigit())
                                        .foregroundColor(Theme.text2)
                                }
                                Spacer()
                                if let difficulty = rack.drillDifficulty {
                                    Text(DrillDifficultyLevel(rawValue: difficulty)?.label ?? difficulty)
                                        .font(.caption2.weight(.semibold))
                                        .foregroundColor(Theme.muted)
                                        .lineLimit(1)
                                }
                            }
                            if let tags = rack.drillTags, !tags.isEmpty {
                                HStack(spacing: 5) {
                                    ForEach(tags, id: \.self) { tag in
                                        badge(text: tag, color: Theme.teal)
                                    }
                                }
                            }
                        }
                        .padding(9)
                        .background(Theme.panel2.opacity(0.65))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
    }

    private var errorsSection: some View {
        let rs = session.racks
        return SectionCard(title: "Unforced errors") {
            LazyVGrid(columns: Layout.fourColumn(), spacing: 8) {
                MiniStatCard(label: "Miss", value: "\(rs.reduce(0) { $0 + $1.missCount })")
                MiniStatCard(label: "Pos", value: "\(rs.reduce(0) { $0 + $1.positionTrackingCount })")
                MiniStatCard(label: "Safety", value: "\(rs.reduce(0) { $0 + $1.safetyCount })")
                MiniStatCard(label: "Pattern", value: "\(rs.reduce(0) { $0 + $1.patternMistakeCount })")
            }
        }
    }

    private var breaksSection: some View {
        let rs = session.racks
        let n = Double(max(rs.count, 1))
        let myB = rs.filter { $0.breaker == "me" }.count
        let dryB = rs.filter { $0.breaker == "me" && $0.breakBalls == 0 }.count
        let rus = rs.filter { $0.outcome == "runout" && $0.result == "won" }.count
        let oRus = rs.filter { $0.outcome == "runout" && $0.result == "lost" }.count
        let bnr = rs.filter { $0.breakAndRun }.count
        let avgP = rs.isEmpty ? 0 : Double(rs.reduce(0) { $0 + Analytics.ep($1, game: session.game) }) / n

        var rows: [(String, String)] = [
            ("Dry breaks", myB == 0 ? "—" : "\(dryB)/\(myB)"),
            ("Runouts", "\(rus)")
        ]
        if session.isPractice {
            let errTotal = rs.reduce(0) { $0 + $1.unforcedErrorCount }
            rows.append(("Err/rack", AppLanguageRuntime.format("%.1f", Double(errTotal) / n)))
        } else {
            rows.append(("Opp runouts", "\(oRus)"))
        }
        rows.append(("B&R", "\(bnr)"))
        rows.append(("Avg potted", AppLanguageRuntime.format("%.1f", avgP)))

        return SectionCard(title: "Break") {
            LazyVGrid(columns: Layout.fourColumn(), spacing: 8) {
                ForEach(rows, id: \.0) { item in
                    MiniStatCard(label: item.0, value: item.1)
                }
            }
        }
    }

    private var rackLogSection: some View {
        let rs = session.racks
        return SectionCard(title: "Rack log") {
            VStack(spacing: 8) {
                ForEach(Array(rs.enumerated()), id: \.offset) { idx, r in
                    let err = r.unforcedErrorCount
                    HStack(spacing: 8) {
                        Text("\(idx + 1)")
                            .font(.caption)
                            .foregroundColor(Theme.muted)
                            .frame(width: 20, alignment: .leading)
                        Text(
                            SummaryCopy.rackResultLabel(isPractice: session.isPractice, result: r.result)
                        )
                            .font(.caption)
                            .foregroundColor(r.result == "won" ? Theme.teal : (r.result == "lost" ? Theme.red : Theme.amber))
                            .frame(width: 40, alignment: .leading)
                        Text(SummaryCopy.outcomeLabel(r.outcome))
                            .font(.caption)
                            .foregroundColor(Theme.purple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.panel2)
                            .cornerRadius(4)
                        Text(SummaryCopy.rackErrorsText(err))
                            .font(.caption2)
                            .foregroundColor(Theme.muted)
                        Spacer()
                        if r.breakAndRun {
                            Text("B&R")
                                .font(.caption2)
                                .foregroundColor(Theme.amber)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func metaText() -> String {
        SummaryCopy.metaText(for: session)
    }

    private func badge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(color.opacity(0.28), lineWidth: 0.5))
            .cornerRadius(5)
    }

    private func saveLabel() {
        let trimmed = labelText.trimmingCharacters(in: .whitespaces)
        Task { await store.updateSessionLabel(sessionID: session.id, label: trimmed) }
    }

    private func savePerformanceRating(_ rating: Int) {
        Task { await store.updateSessionMeta(sessionID: session.id, performanceRating: rating) }
    }

    private func saveOpponent() {
        Task { await store.updateSessionMeta(sessionID: session.id, opponent: opponentText.trimmingCharacters(in: .whitespaces)) }
    }

    private func finishSummary() {
        saveLabel()
        if !session.isPractice {
            saveOpponent()
        }
        if let performanceRating {
            savePerformanceRating(performanceRating)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onCompletion?()
    }

    private var opponentSuggestions: [String] {
        let names = opponentStore.availableNames(from: store.sessions)
            .filter { $0 != "All opponents" }
        let current = opponentText.trimmingCharacters(in: .whitespacesAndNewlines)
        return names.filter { current.isEmpty || $0 != current }
    }
}

private extension UIColor {
    var rgbaComponents: (r: Double, g: Double, b: Double, a: Double) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
    }
}

private struct SummaryMatchShareSection: View {
    @EnvironmentObject private var socialProfileStore: SocialProfileStore

    let session: Session
    @Binding var selectedFriendCode: String

    var body: some View {
        SectionCard(title: "Share match") {
            VStack(alignment: .leading, spacing: 12) {
                if socialProfileStore.profile == nil {
                    shareHint(SummaryCopy.shareProfileHint)
                } else if socialProfileStore.friends.isEmpty {
                    shareHint(SummaryCopy.shareNoFriendsHint)
                } else {
                    friendSelector
                    selectedFriendShareControls
                }
            }
        }
    }

    private var friendSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(socialProfileStore.friends) { friend in
                    let isSelected = selectedFriend?.friendCode == friend.friendCode
                    Button {
                        selectedFriendCode = friend.friendCode
                        socialProfileStore.resetMatchShareState()
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(friend.displayName)
                                .font(.caption.weight(.bold))
                                .lineLimit(1)
                            Text(friend.friendCode)
                                .font(.caption2.monospaced())
                                .lineLimit(1)
                        }
                        .foregroundColor(isSelected ? Theme.text : Theme.text2)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(isSelected ? Theme.purple.opacity(0.22) : Theme.panel2.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(isSelected ? Theme.purple.opacity(0.65) : Theme.border, lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var selectedFriendShareControls: some View {
        if let friend = selectedFriend {
            let shareState = SummaryMatchShareState(
                sessionUUID: session.sessionUUID,
                friendCode: friend.friendCode,
                friendDisplayName: friend.displayName,
                latestShare: socialProfileStore.latestOutgoingShare(for: session, friendCode: friend.friendCode),
                matchShareState: socialProfileStore.matchShareState,
                refreshState: socialProfileStore.outgoingShareRefreshState
            )
            let copy = shareState.presentation

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    shareStatusChip(label: copy.statusLabel, tone: copy.statusTone)
                    Spacer(minLength: 0)
                    Text("\(session.wins):\(session.losses)")
                        .font(.caption.weight(.black).monospacedDigit())
                        .foregroundColor(Theme.text)

                    Button {
                        Task { await socialProfileStore.refreshOutgoingShares(for: session.sessionUUID) }
                    } label: {
                        Image(systemName: shareState.isRefreshingCurrentSession ? "hourglass" : "arrow.clockwise")
                            .font(.caption.weight(.bold))
                            .foregroundColor(Theme.teal)
                            .frame(width: 28, height: 28)
                            .background(Theme.teal.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(shareState.isRefreshingCurrentSession)
                }

                Button {
                    Task { await socialProfileStore.shareMatch(session, with: friend) }
                } label: {
                    HStack(spacing: 8) {
                        if shareState.isSendingCurrentFriend {
                            ProgressView()
                                .tint(Theme.text)
                        }
                        Text(copy.buttonTitle)
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundColor(Theme.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(color(for: copy.buttonTone))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(shareState.isActionDisabled)

                if let message = copy.message {
                    Text(message)
                        .font(.caption2)
                        .foregroundColor(color(for: copy.messageTone))
                }
            }
        }
    }

    private var selectedFriend: SocialFriend? {
        let code = selectedFriendCode.isEmpty ? socialProfileStore.friends.first?.friendCode : selectedFriendCode
        guard let code else { return nil }
        return socialProfileStore.friends.first { $0.friendCode == code } ?? socialProfileStore.friends.first
    }

    private func shareHint(_ hint: ShareHintCopy) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(hint.title)
                .font(.caption.weight(.bold))
                .foregroundColor(Theme.text2)
            Text(hint.message)
                .font(.caption2)
                .foregroundColor(Theme.muted)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.panel2.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func shareStatusChip(label: String, tone: AppCopyTone) -> some View {
        let color = color(for: tone)
        return Text(label)
            .font(.caption2.weight(.bold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 0.6))
    }

    private func color(for tone: AppCopyTone) -> Color {
        switch tone {
        case .accent:
            return Theme.teal
        case .success:
            return Theme.green
        case .warning:
            return Theme.amber
        case .danger:
            return Theme.red
        case .muted:
            return Theme.muted
        }
    }
}
