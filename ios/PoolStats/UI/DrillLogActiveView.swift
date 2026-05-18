import SwiftUI
import UIKit

struct DrillLogActiveView: View {
    @EnvironmentObject private var store: SessionLogStore
    @EnvironmentObject private var historyStore: DataStore
    @State private var selectedTags: Set<String> = []
    @State private var ballsMade: Double = 0
    @State private var currentLevel: DrillDifficultyLevel = .standard
    @State private var showPicture = false
    @State private var toast: String?
    @State private var attemptsExpanded = false
    @State private var liteSelectedLevel: DrillDifficultyLevel = .standard
    @Binding var showEndConfirm: Bool
    let showLiteMode: Bool
    let onExitLite: (() -> Void)?
    let onEnterLite: (() -> Void)?

    private let mistakeOptions = ["Potting", "Position", "Pattern", "Runout"]
    private var session: Session? { store.currentSession }
    private var template: DrillTemplate? { DrillLibrary.template(id: session?.drillID) }
    private var targetBallCount: Int { currentDifficulty?.ballCount ?? session?.drillBallCount ?? 0 }
    private var targetCountText: String { template?.countText(targetBallCount) ?? "\(targetBallCount) reps" }
    private var progressTitle: String { template?.progressTitle() ?? "Completed" }
    private var currentDifficulty: DrillDifficulty? {
        guard let template else { return nil }
        return template.difficultyLevels.first(where: { $0.level == currentLevel }) ?? template.standardDifficulty
    }
    private var attempts: Int { session?.drillAttempts ?? 0 }
    private var successes: Int { session?.drillSuccesses ?? 0 }
    private var misses: Int { session?.drillMisses ?? 0 }
    private var successRate: String { session?.drillSuccessRate.map { "\($0)%" } ?? "--" }
    private var canLogSuccess: Bool { Int(ballsMade) >= targetBallCount }
    private var canLogMiss: Bool { Int(ballsMade) < targetBallCount }

    init(
        showEndConfirm: Binding<Bool>,
        showLiteMode: Bool = false,
        onExitLite: (() -> Void)? = nil,
        onEnterLite: (() -> Void)? = nil
    ) {
        _showEndConfirm = showEndConfirm
        self.showLiteMode = showLiteMode
        self.onExitLite = onExitLite
        self.onEnterLite = onEnterLite
    }

    var body: some View {
        if let session, session.isDrillPractice {
            Group {
                if showLiteMode {
                    liteLayout(session)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        practiceHeader(session)
                        scorePanel(session)
                        compactDifficulty
                        mistakesPanel
                        pottedPanel
                        actionPanel
                        attemptLog(session)
                        if let toast {
                            Text(toast)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Theme.green)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .transition(.opacity)
                        }
                    }
                }
            }
            .padding(.top, 4)
            .padding(.bottom, showLiteMode ? 12 : 118)
            .onAppear { hydrateDifficulty(from: session) }
            .onChange(of: session.drillDifficulty) { _ in hydrateDifficulty(from: session) }
            .onChange(of: currentLevel) { newLevel in
                liteSelectedLevel = newLevel
            }
            .fullScreenCover(isPresented: $showPicture) {
                if let template, let currentDifficulty {
                    DrillPictureExpandedView(template: template, difficulty: currentDifficulty)
                }
            }
        } else {
            EmptyView()
        }
    }

    private func practiceHeader(_ session: Session) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(session.drillTitle ?? "Drill")
                        .font(.title3.bold())
                        .foregroundColor(Theme.text)
                        .lineLimit(2)
                    Text(metaLine(session))
                        .font(.caption.weight(.medium))
                        .foregroundColor(Theme.text2)
                }
                Spacer(minLength: 4)
                HStack(spacing: 8) {
                    if let onEnterLite {
                        Button {
                            onEnterLite()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "rectangle.split.3x1")
                                    .font(.caption.weight(.bold))
                                Text("Lite")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundColor(Theme.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Theme.blue.opacity(0.12))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Theme.blue.opacity(0.28), lineWidth: 0.6))
                        }
                        .buttonStyle(.plain)
                    }

                    Button { showPicture = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "rectangle.expand.vertical")
                                .font(.caption.weight(.bold))
                            Text("See layout")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundColor(Theme.teal)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Theme.teal.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Theme.teal.opacity(0.28), lineWidth: 0.6))
                    }
                    .buttonStyle(.plain)
                }
            }

            if let label = session.drillTargetLabel {
                Text(label)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(Theme.amber)
            }
        }
        .padding(14)
        .background(LinearGradient(colors: [Theme.panel2, Theme.panel.opacity(0.92)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.border, lineWidth: 0.6))
    }

    private func scorePanel(_ session: Session) -> some View {
        TimelineView(.periodic(from: Date(), by: 1)) { _ in
            let elapsed = elapsedSince(store.sessionStart)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("W:L")
                        .font(.caption2.weight(.black))
                        .foregroundColor(Theme.muted)
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("\(successes)")
                            .foregroundColor(Theme.green)
                        Text(":")
                            .foregroundColor(Theme.text2)
                        Text("\(misses)")
                            .foregroundColor(Theme.red)
                    }
                    .font(.system(size: 42, weight: .black, design: .rounded).monospacedDigit())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    Text(AppFormatters.elapsed(elapsed))
                        .font(.headline.weight(.bold).monospacedDigit())
                        .foregroundColor(Theme.text)
                    Text("\(attempts) attempts · \(successRate)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.muted)
                    if let progress = session.drillTargetProgress {
                        ProgressView(value: Double(progress.current), total: Double(max(progress.target, 1)))
                            .tint(Theme.green)
                            .frame(width: 112)
                    }
                }
            }
            .padding(14)
            .background(Theme.panel2.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.border, lineWidth: 0.6))
        }
    }

    private var compactDifficulty: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Button { stepDifficulty(-1) } label: {
                    Image(systemName: "minus")
                        .font(.caption.weight(.black))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .foregroundColor(Theme.text)
                .background(Theme.panel2)
                .clipShape(Circle())
                .disabled(currentDifficultyIndex <= 0)
                .opacity(currentDifficultyIndex <= 0 ? 0.35 : 1)

                VStack(alignment: .leading, spacing: 2) {
                    Text(currentDifficulty?.level.label ?? "Difficulty")
                        .font(.caption.weight(.black))
                        .foregroundColor(difficultyColor(for: currentLevel))
                    Text(targetCountText)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.text2)
                }

                Spacer()

                Text("Difficulty")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(Theme.muted)

                Button { stepDifficulty(1) } label: {
                    Image(systemName: "plus")
                        .font(.caption.weight(.black))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .foregroundColor(Theme.text)
                .background(Theme.panel2)
                .clipShape(Circle())
                .disabled(currentDifficultyIndex >= maxDifficultyIndex)
                .opacity(currentDifficultyIndex >= maxDifficultyIndex ? 0.35 : 1)
            }

            if let constraint = currentDifficulty?.localizedConstraint {
                Text(constraint)
                    .font(.caption)
                    .foregroundColor(Theme.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.panel2.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 0.5))
    }

    private var mistakesPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Mistakes")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Theme.text)
                Spacer()
                if !selectedTags.isEmpty {
                    Button("Clear") { selectedTags.removeAll() }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.muted)
                }
            }
            DrillMistakeTagGrid(options: mistakeOptions, selectedTags: $selectedTags)
        }
        .padding(12)
        .background(Theme.panel2.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.border, lineWidth: 0.6))
    }

    private var pottedPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(progressTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Theme.text)
                Spacer()
                Text("\(Int(ballsMade))/\(targetBallCount)")
                    .font(.headline.weight(.bold).monospacedDigit())
                    .foregroundColor(pottedColor)
            }
            PottedAttemptSlider(value: $ballsMade, maxValue: max(targetBallCount, 1))
                .onChange(of: targetBallCount) { newValue in
                    ballsMade = min(ballsMade, Double(max(newValue, 0)))
                }
        }
        .padding(12)
        .background(Theme.panel2.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.border, lineWidth: 0.6))
    }

    private var pottedColor: Color {
        canLogSuccess ? Theme.green : Theme.amber
    }

    private var actionPanel: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                outcomeButton(title: "Miss", icon: "xmark", color: Theme.red, disabled: !canLogMiss) { recordCurrent(outcome: "miss") }
                outcomeButton(title: "Success", icon: "checkmark", color: Theme.green, disabled: !canLogSuccess) { recordCurrent(outcome: "success") }
            }
            Button { saveAttemptAndExit() } label: {
                Text("Save & Exit")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Theme.purple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Theme.purple.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.purple.opacity(0.28), lineWidth: 0.8))
            }
            .buttonStyle(.plain)
        }
    }

    private func outcomeButton(title: String, icon: String, color: Color, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption.weight(.black))
                Text(title)
                    .font(.headline.weight(.bold))
            }
            .foregroundColor(disabled ? Theme.muted : .black.opacity(0.82))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(disabled ? Theme.panel2 : color)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(disabled ? Theme.border : color.opacity(0.4), lineWidth: 0.8))
            .shadow(color: disabled ? Color.clear : color.opacity(0.22), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private func attemptLog(_ session: Session) -> some View {
        DisclosureGroup(isExpanded: $attemptsExpanded) {
            VStack(spacing: 7) {
                if session.racks.isEmpty {
                    Text("No attempts logged yet.")
                        .font(.subheadline)
                        .foregroundColor(Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    ForEach(session.racks.reversed()) { rack in
                        attemptRow(rack)
                    }
                }
            }
            .padding(.top, 8)
        } label: {
            HStack {
                Text("Attempts")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Theme.text)
                Spacer()
                Text("\(attempts)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundColor(Theme.muted)
            }
        }
        .tint(Theme.text2)
        .padding(14)
        .background(Theme.panel2.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.border, lineWidth: 0.6))
    }

    private func attemptRow(_ rack: Rack) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 9) {
                Text("#\(rack.index)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Theme.muted)
                    .frame(width: 34, alignment: .leading)
                Image(systemName: rack.drillOutcome == "success" ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(rack.drillOutcome == "success" ? Theme.green : Theme.red)
                Text("\(rack.drillBallsMade ?? 0)/\(rack.drillTargetBallCount ?? targetBallCount)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundColor(Theme.text)
                Spacer()
                if let difficulty = rack.drillDifficulty {
                    Text(DrillDifficultyLevel(rawValue: difficulty)?.label ?? difficulty)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(Theme.muted)
                }
            }
            if let tags = rack.drillTags, !tags.isEmpty {
                HStack(spacing: 5) {
                    ForEach(tags, id: \.self) { tag in
                        drillBadge(tag, color: drillColor(tag))
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(10)
        .background(Theme.bg.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func recordCurrent(outcome: String) {
        guard (outcome == "success" && canLogSuccess) || (outcome == "miss" && canLogMiss) else { return }
        let target = targetBallCount
        let made = outcome == "success" ? target : min(Int(ballsMade), max(target - 1, 0))
        if store.recordDrillAttempt(outcome: outcome, tags: Array(selectedTags).sorted(), ballsMade: made, targetBallCount: target, difficulty: currentLevel.rawValue) {
            UINotificationFeedbackGenerator().notificationOccurred(outcome == "success" ? .success : .warning)
            toast = outcome == "success" ? "Success logged." : "Miss logged."
            ballsMade = 0
            selectedTags.removeAll()
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                toast = nil
            }
        }
    }

    private func saveAttemptAndExit() {
        let target = targetBallCount
        let made = min(Int(ballsMade), target)
        let outcome = made >= target ? "success" : "miss"
        _ = store.recordDrillAttempt(outcome: outcome, tags: Array(selectedTags).sorted(), ballsMade: made, targetBallCount: target, difficulty: currentLevel.rawValue)
        Task { await store.endSession(savingTo: historyStore) }
    }

    private func hydrateDifficulty(from session: Session) {
        if let level = session.drillDifficultyLevel {
            currentLevel = level
            liteSelectedLevel = level
        }
        ballsMade = min(ballsMade, Double(max(session.drillBallCount ?? 0, 0)))
    }

    private func stepDifficulty(_ delta: Int) {
        guard let template else { return }
        let nextIndex = min(max(currentDifficultyIndex + delta, 0), template.difficultyLevels.count - 1)
        let difficulty = template.difficultyLevels[nextIndex]
        currentLevel = difficulty.level
        ballsMade = min(ballsMade, Double(difficulty.ballCount))
        store.updateDrillDifficulty(level: difficulty.level, ballCount: difficulty.ballCount)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private var currentDifficultyIndex: Int {
        template?.difficultyLevels.firstIndex(where: { $0.level == currentLevel }) ?? 0
    }

    private var maxDifficultyIndex: Int {
        max((template?.difficultyLevels.count ?? 1) - 1, 0)
    }

    private func metaLine(_ session: Session) -> String {
        [currentDifficulty?.level.label ?? session.drillDifficultyLabel, targetCountText]
            .joined(separator: " · ")
    }

    private func elapsedSince(_ start: Date?) -> TimeInterval {
        guard let start else { return 0 }
        return max(0, Date().timeIntervalSince(start))
    }

    private func applyLiteDifficulty(_ level: DrillDifficultyLevel) {
        guard let template else { return }
        let difficulty = template.difficultyLevels.first(where: { $0.level == level }) ?? template.standardDifficulty
        currentLevel = difficulty.level
        ballsMade = min(ballsMade, Double(difficulty.ballCount))
        store.updateDrillDifficulty(level: difficulty.level, ballCount: difficulty.ballCount)
    }

    private func liteLayout(_ session: Session) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.drillTitle ?? "Drill")
                            .font(.headline.weight(.bold))
                            .foregroundColor(Theme.text)
                        Text(metaLine(session))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Theme.text2)
                        if let target = session.drillTargetLabel {
                            Text(target)
                                .font(.caption2.weight(.bold))
                                .foregroundColor(Theme.amber)
                        }
                    }
                    Spacer(minLength: 0)
                    Button {
                        showPicture = true
                    } label: {
                        Image(systemName: "rectangle.expand.vertical")
                            .font(.caption.weight(.bold))
                            .foregroundColor(Theme.teal)
                            .frame(width: 32, height: 32)
                            .background(Theme.teal.opacity(0.12))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Theme.teal.opacity(0.28), lineWidth: 0.7))
                    }
                    .buttonStyle(.plain)
                }

                DrillMistakeTagGrid(options: mistakeOptions, selectedTags: $selectedTags)

                HStack(spacing: 8) {
                    Button {
                        saveAttemptAndExit()
                    } label: {
                        Text("Save & Exit")
                            .font(.caption.weight(.bold))
                            .foregroundColor(Theme.purple)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(Theme.purple.opacity(0.16))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.purple.opacity(0.28), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)

                    if let onExitLite {
                        Button {
                            onExitLite()
                        } label: {
                            Text("Exit Lite")
                                .font(.caption.weight(.bold))
                                .foregroundColor(Theme.text2)
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .background(Theme.panel2)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Theme.panel2.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.border, lineWidth: 0.6))

            VStack(alignment: .leading, spacing: 10) {
                TimelineView(.periodic(from: Date(), by: 1)) { _ in
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(successes)")
                            .font(.system(size: 70, weight: .black, design: .rounded).monospacedDigit())
                            .foregroundColor(Theme.green)
                        Text(":")
                            .font(.system(size: 52, weight: .black, design: .rounded))
                            .foregroundColor(Theme.text2)
                        Text("\(misses)")
                            .font(.system(size: 70, weight: .black, design: .rounded).monospacedDigit())
                            .foregroundColor(Theme.red)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text(AppFormatters.elapsed(elapsedSince(store.sessionStart)))
                                .font(.headline.weight(.bold).monospacedDigit())
                                .foregroundColor(Theme.text)
                            Text("\(attempts) attempts")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Theme.muted)
                            Text(successRate)
                                .font(.caption.weight(.bold))
                                .foregroundColor(Theme.text2)
                        }
                    }
                }

                HStack {
                    Text(progressTitle)
                        .font(.caption.weight(.bold))
                        .foregroundColor(Theme.text2)
                    Spacer()
                    Text("\(Int(ballsMade))/\(targetBallCount)")
                        .font(.headline.weight(.bold).monospacedDigit())
                        .foregroundColor(pottedColor)
                }
                PottedAttemptSlider(value: $ballsMade, maxValue: max(targetBallCount, 1))

                HStack(spacing: 8) {
                    outcomeButton(title: "Miss", icon: "xmark", color: Theme.red, disabled: !canLogMiss) { recordCurrent(outcome: "miss") }
                    outcomeButton(title: "Success", icon: "checkmark", color: Theme.green, disabled: !canLogSuccess) { recordCurrent(outcome: "success") }
                }

                if let toast {
                    Text(toast)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.green)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Theme.panel2.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.border, lineWidth: 0.6))

            VStack(alignment: .leading, spacing: 10) {
                Text("Difficulty")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Theme.muted)

                if let template {
                    DifficultyGradientSlider(levels: template.difficultyLevels, selectedLevel: $liteSelectedLevel)
                        .onChange(of: liteSelectedLevel) { newValue in
                            applyLiteDifficulty(newValue)
                        }
                }

                if let difficulty = currentDifficulty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(difficulty.level.label)
                            .font(.caption.weight(.bold))
                            .foregroundColor(difficultyColor(for: difficulty.level))
                        Text(template?.countText(difficulty.ballCount) ?? AppLanguageRuntime.localizedFormat("%lld reps", difficulty.ballCount))
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(Theme.text2)
                        Text(difficulty.localizedConstraint)
                            .font(.caption2)
                            .foregroundColor(Theme.muted)
                            .lineLimit(3)
                    }
                    .padding(10)
                    .background(Theme.panel.opacity(0.65))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.6))
                }

                Spacer(minLength: 0)
                if let progress = session.drillTargetProgress {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Target progress")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(Theme.muted)
                        ProgressView(value: Double(progress.current), total: Double(max(progress.target, 1)))
                            .tint(Theme.green)
                        Text("\(progress.current)/\(progress.target)")
                            .font(.caption2.weight(.bold).monospacedDigit())
                            .foregroundColor(Theme.text2)
                    }
                }
            }
            .padding(12)
            .frame(width: 230)
            .frame(maxHeight: .infinity, alignment: .topLeading)
            .background(Theme.panel2.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.border, lineWidth: 0.6))
        }
        .padding(.horizontal, 10)
    }
}
