import SwiftUI

struct LogActiveView: View {
    @EnvironmentObject private var store: SessionLogStore
    @Binding var showSaveToast: Bool
    @Binding var showEndConfirm: Bool
    let showLiteScoreboard: Bool
    let onScoreCardTap: (() -> Void)?

    var body: some View {
        if let session = store.currentSession, let rack = store.currentRack {
            Group {
                if showLiteScoreboard {
                    LandscapeScoreboardView(
                        session: session,
                        rack: rack,
                        showSaveToast: $showSaveToast,
                        showEndConfirm: $showEndConfirm,
                        onDismiss: onScoreCardTap
                    )
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        header(session: session, rack: rack)

                        if store.sessionStart != nil {
                            LogTimerRow(session: session, onScoreCardTap: onScoreCardTap)
                        }

                        LogSectionCard(title: "Break") {
                            BreakSection(rack: rack)
                        }

                        LogSectionCard(title: "Layout difficulty") {
                            LayoutSection(rack: rack)
                        }

                        LogSectionCard(title: "Unforced errors") {
                            ErrorSection(rack: rack)
                        }

                        LogSectionCard(title: "Result") {
                            ResultSection(rack: rack, session: session)
                        }

                        ActionRow(rack: rack, isPractice: session.isPractice, showSaveToast: $showSaveToast, showEndConfirm: $showEndConfirm)

                        if showSaveToast {
                            Text("Rack saved. Ready for the next one.")
                                .font(.caption2)
                                .foregroundColor(Theme.green)
                                .transition(.opacity)
                        }

                        if let notice = store.externalUpdateNotice {
                            Text(notice)
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(Theme.teal)
                                .transition(.opacity)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            EmptyView()
        }
    }

    private func header(session: Session, rack: Rack) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Rack #\(rack.index)")
                    .font(.headline)
                Spacer()
                Text(metaText(session))
                    .font(.caption)
                    .foregroundColor(Theme.muted)
            }

            if !session.label.isEmpty {
                Text(session.label)
                    .font(.caption)
                    .foregroundColor(Theme.text2)
            }
        }
    }

    private func metaText(_ session: Session) -> String {
        let game = session.game == "8ball" ? "8-ball" : "9-ball"
        let type = session.isPractice ? "practice" : "match"
        return session.label.isEmpty ? "\(game) \(type)" : "\(game) \(type) · \(session.label)"
    }

}

// MARK: - Full-view sections

private struct BreakSection: View {
    @EnvironmentObject private var store: SessionLogStore
    let rack: Rack

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ChoiceButton(label: "Me", isOn: rack.breaker == "me", color: Theme.green) {
                    store.updateRack { $0.breaker = "me" }
                }
                ChoiceButton(label: "Opp", isOn: rack.breaker == "opp", color: Theme.amber) {
                    store.updateRack { $0.breaker = "opp" }
                }
            }

            HStack(spacing: 8) {
                let breakColors: [Int: Color] = [
                    0: Theme.red,
                    1: Theme.amber,
                    2: Theme.blue,
                    3: Theme.green
                ]
                ForEach([0, 1, 2, 3], id: \.self) { n in
                    ChoiceButton(label: n == 3 ? "3+" : "\(n)", isOn: rack.breakBalls == n, color: breakColors[n] ?? Theme.purple) {
                        store.updateRack { $0.breakBalls = n }
                    }
                }
                ChoiceButton(label: "Foul", isOn: rack.breakFoul, color: Theme.red) {
                    store.updateRack { $0.breakFoul.toggle() }
                }
            }
        }
    }
}

private struct LayoutSection: View {
    @EnvironmentObject private var store: SessionLogStore
    let rack: Rack

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Layout")
                .font(.caption)
                .foregroundColor(Theme.text2)
            HStack(spacing: 8) {
                ChoiceButton(label: "Open", isOn: rack.layout == "open", color: Theme.green) {
                    store.updateRack { $0.layout = "open" }
                }
                ChoiceButton(label: "Clustered", isOn: rack.layout == "clustered", color: Theme.amber) {
                    store.updateRack { $0.layout = "clustered" }
                }
                ChoiceButton(label: "Problem", isOn: rack.layout == "problematic", color: Theme.red) {
                    store.updateRack { $0.layout = "problematic" }
                }
                ChoiceButton(label: "Snookered", isOn: rack.layout == "snookered", color: Theme.purple) {
                    store.updateRack { $0.layout = "snookered" }
                }
            }
        }
    }
}

private struct ErrorSection: View {
    @EnvironmentObject private var store: SessionLogStore
    let rack: Rack

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                ErrorCounterTile(label: "Miss", value: rack.missCount, color: Theme.teal) {
                    store.updateRack { $0.missCount += 1 }
                } decrement: {
                    store.updateRack { $0.missCount = max(0, $0.missCount - 1) }
                }

                ErrorCounterTile(label: "Position", value: rack.positionTrackingCount, color: Theme.amber) {
                    store.updateRack { $0.badPosition += 1 }
                } decrement: {
                    store.updateRack { $0.badPosition = max(0, $0.badPosition - 1) }
                }

                ErrorCounterTile(label: "Safety", value: rack.safetyCount, color: Theme.blue) {
                    store.updateRack { $0.badSafety += 1 }
                } decrement: {
                    store.updateRack { $0.badSafety = max(0, $0.badSafety - 1) }
                }

                ErrorCounterTile(label: "Pattern", value: rack.patternMistakeCount, color: Theme.purple) {
                    store.updateRack { $0.patternCount += 1 }
                } decrement: {
                    store.updateRack { $0.patternCount = max(0, $0.patternCount - 1) }
                }
            }
        }
    }
}

private struct ResultSection: View {
    @EnvironmentObject private var store: SessionLogStore
    let rack: Rack
    let session: Session

    var body: some View {
        if !session.isPractice {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    ChoiceButton(label: "Won", isOn: rack.result == "won", color: Theme.green) {
                        store.updateRack { r in
                            r.result = "won"
                            if r.outcome == nil { r.outcome = "noRunout" }
                        }
                    }
                    ChoiceButton(label: "Lost", isOn: rack.result == "lost", color: Theme.red) {
                        store.updateRack { r in
                            r.result = "lost"
                            r.outcome = "noRunout"
                            r.runoutFirst = false
                            r.breakAndRun = false
                        }
                    }
                }

                if rack.result == "won" {
                    HStack(spacing: 8) {
                        SmallToggleButton(label: "Runout at first visit", isOn: rack.converted, color: Theme.teal) {
                            store.updateRack { r in
                                let next = !(r.outcome == "runout")
                                r.outcome = next ? "runout" : "noRunout"
                                r.runoutFirst = next
                            }
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }
}

private struct ActionRow: View {
    @EnvironmentObject private var store: SessionLogStore
    let rack: Rack
    let isPractice: Bool
    @Binding var showSaveToast: Bool
    @Binding var showEndConfirm: Bool

    var body: some View {
        HStack(spacing: 10) {
            Button("Next Rack") {
                if store.saveRack() {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    showSaveToast = true
                    Task {
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        showSaveToast = false
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.teal)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .cornerRadius(10)
            .disabled(!canSave(rack: rack, isPractice: isPractice))

            Button("Save & Exit") {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showEndConfirm = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.red)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .cornerRadius(10)
        }
    }

    private func canSave(rack: Rack, isPractice: Bool) -> Bool {
        let breakOK = rack.breaker != "none" && rack.breakBalls >= 0
        let convertedOK = isPractice ? true : rack.outcome != nil
        let resultOK = isPractice ? true : rack.result != nil
        return breakOK && convertedOK && resultOK
    }
}

private struct LogTimerRow: View {
    @EnvironmentObject private var store: SessionLogStore
    let session: Session
    let onScoreCardTap: (() -> Void)?

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1)) { _ in
            let now = Date()
            let sessionElapsed = elapsedSince(store.sessionStart, now: now)
            let rawRackElapsed = elapsedSince(store.rackStart, now: now)
            let bufferSeconds = Session.rackSetupBufferSeconds
            let inBuffer = rawRackElapsed < bufferSeconds
            let rackElapsed = max(0, rawRackElapsed - bufferSeconds)
            let activeRackCount = max(session.racks.count + 1, 1)
            let avgPerRack = session.bufferedAverageRackSeconds(totalSeconds: sessionElapsed, rackCount: activeRackCount)
            let rackProgress: Double = {
                if inBuffer {
                    return min(rawRackElapsed / max(bufferSeconds, 1), 1)
                }
                let targetActiveRackSeconds: TimeInterval = 60
                return min(rackElapsed / targetActiveRackSeconds, 1)
            }()
            let rackTimerColor = inBuffer ? Theme.amber : Theme.green

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    timeChip(label: "Session", value: AppFormatters.elapsed(sessionElapsed))
                    timeChip(label: "Rack", value: AppFormatters.elapsed(rackElapsed), valueColor: rackTimerColor)
                    timeChip(label: "Avg/rack", value: AppFormatters.elapsed(avgPerRack))
                    Spacer()
                    scoreCard(wins: session.wins, losses: session.losses)
                }
                rackProgressBar(progress: rackProgress, inBuffer: inBuffer)
            }
        }
    }

    private func elapsedSince(_ start: Date?, now: Date) -> TimeInterval {
        guard let start else { return 0 }
        return max(0, now.timeIntervalSince(start))
    }

    private func timeChip(label: String, value: String, valueColor: Color = Theme.text) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(Theme.muted)
            Text(value)
                .font(.caption)
                .foregroundColor(valueColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Theme.panel)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 0.5))
    }

    private func rackProgressBar(progress: Double, inBuffer: Bool) -> some View {
        let fill = min(max(progress, 0), 1)
        let barColor = inBuffer ? Theme.amber : Theme.green
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(inBuffer ? "Rack setup buffer (45s)" : "Rack timer")
                    .font(.caption2)
                    .foregroundColor(Theme.muted)
                Spacer(minLength: 0)
                Text(inBuffer ? "buffering" : "live")
                    .font(.caption2)
                    .foregroundColor(barColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Theme.border)
                        .frame(height: 5)
                    Rectangle()
                        .fill(barColor)
                        .frame(width: geo.size.width * fill, height: 5)
                }
                .cornerRadius(2.5)
            }
            .frame(height: 5)
        }
    }

    @ViewBuilder
    private func scoreCard(wins: Int, losses: Int) -> some View {
        let card = HStack(spacing: 0) {
            Text("\(wins)")
                .foregroundColor(Theme.green)
            Text(":")
                .foregroundColor(Theme.muted)
            Text("\(losses)")
                .foregroundColor(Theme.red)
        }
        .font(.headline)
        .monospacedDigit()
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Theme.panel)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
        .accessibilityLabel("Score \(wins) to \(losses)")

        if let onScoreCardTap {
            Button(action: onScoreCardTap) {
                card
            }
            .buttonStyle(.plain)
        } else {
            card
        }
    }
}

// MARK: - Lite scoreboard (landscape / forced)

private struct LandscapeScoreboardView: View {
    enum Side { case me, opp }

    @EnvironmentObject private var store: SessionLogStore
    @EnvironmentObject private var profileStore: PlayerProfileStore
    let session: Session
    let rack: Rack
    @Binding var showSaveToast: Bool
    @Binding var showEndConfirm: Bool
    var onDismiss: (() -> Void)? = nil

    @State private var pulsingSide: Side? = nil
    @State private var pressingSide: Side? = nil
    @State private var pressProgress: CGFloat = 0
    @State private var cancelReadySide: Side? = nil
    @State private var scorePressTask: Task<Void, Never>? = nil
    @State private var showMenu: Bool = false
    @State private var showTrackingControls: Bool = false

    private var userName: String { profileStore.profile.displayName }
    private var oppName: String {
        let n = session.opponent.trimmingCharacters(in: .whitespaces)
        return n.isEmpty ? "Opponent" : n
    }

    var body: some View {
        HStack(spacing: 0) {
            if showTrackingControls {
                layoutColumn
                    .frame(width: 92)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            centerColumn
                .frame(maxWidth: .infinity)

            if showTrackingControls {
                errorsColumn
                    .frame(width: 92)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: showTrackingControls)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.ignoresSafeArea())
        .overlay(alignment: .top) {
            menuDot.padding(.top, 4)
        }
        .overlay {
            if showMenu {
                customMenuOverlay
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: center (names + score)

    private var centerColumn: some View {
        GeometryReader { geo in
            let scoreFontSize = scoreFontSize(for: geo.size)

            HStack(alignment: .center, spacing: 16) {
                playerPanel(name: userName, side: .me, color: Theme.green, score: session.wins, scoreFontSize: scoreFontSize)
                Text(":")
                    .font(.system(size: scoreFontSize * 0.38, weight: .ultraLight, design: .rounded))
                    .foregroundColor(Theme.muted.opacity(0.3))
                    .offset(y: -scoreFontSize * 0.07)
                playerPanel(name: oppName, side: .opp, color: Theme.red, score: session.losses, scoreFontSize: scoreFontSize)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: showTrackingControls)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 12)
    }

    private func scoreFontSize(for size: CGSize) -> CGFloat {
        let heightLimit = size.height * (showTrackingControls ? 0.61 : 0.76)
        let widthLimit = size.width * (showTrackingControls ? 0.34 : 0.40)
        let maxSize: CGFloat = showTrackingControls ? 230 : 320
        return min(maxSize, max(150, min(heightLimit, widthLimit)))
    }

    private func playerPanel(name: String, side: Side, color: Color, score: Int, scoreFontSize: CGFloat) -> some View {
        let isBreaker = (side == .me && rack.breaker == "me") || (side == .opp && rack.breaker == "opp")
        let isPulsing = pulsingSide == side
        let isPressing = pressingSide == side
        let scale: CGFloat = isPressing ? 0.94 : (isPulsing ? 1.18 : 1.0)
        return VStack(spacing: 10) {
            Button {
                store.updateRack { $0.breaker = side == .me ? "me" : "opp" }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: isBreaker ? "circle.fill" : "circle")
                        .font(.system(size: 7))
                        .foregroundColor(isBreaker ? color : Theme.muted.opacity(0.6))
                    Text(name)
                        .font(.callout.weight(.semibold))
                        .foregroundColor(isBreaker ? color : Theme.text2)
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isBreaker ? color.opacity(0.2) : Theme.panel.opacity(0.55))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isBreaker ? color.opacity(0.55) : Theme.border, lineWidth: isBreaker ? 1.2 : 0.7)
                )
            }
            .buttonStyle(.plain)

            Text("\(score)")
                .font(.system(size: scoreFontSize, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.45)
                .opacity(isPressing ? 0.7 : 1.0)
                .scaleEffect(scale)
                .animation(.spring(response: 0.24, dampingFraction: 0.55), value: pressingSide)
                .animation(.spring(response: 0.28, dampingFraction: 0.45), value: pulsingSide)
                .overlay {
                    Circle()
                        .trim(from: 0, to: isPressing ? pressProgress : 0)
                        .stroke(color.opacity(0.6), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: scoreFontSize * 0.87, height: scoreFontSize * 0.87)
                        .opacity(isPressing || pressProgress > 0.02 ? 1 : 0)
                        .allowsHitTesting(false)
                }
                .contentShape(Rectangle())
                .gesture(scorePressGesture(side: side))
        }
    }

    private func scorePressGesture(side: Side) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard pressingSide == nil else { return }
                beginScorePress(side: side)
            }
            .onEnded { _ in
                let shouldCancelScore = cancelReadySide == side
                endScorePress()
                if shouldCancelScore {
                    handleLongPress(side: side)
                } else {
                    handleScoreTap(side: side)
                }
            }
    }

    private func beginScorePress(side: Side) {
        scorePressTask?.cancel()
        pressingSide = side
        cancelReadySide = nil
        pressProgress = 0
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.linear(duration: 0.55)) {
            pressProgress = 1.0
        }
        scorePressTask = Task {
            try? await Task.sleep(nanoseconds: 550_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard pressingSide == side else { return }
                cancelReadySide = side
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
    }

    private func endScorePress() {
        scorePressTask?.cancel()
        scorePressTask = nil
        pressingSide = nil
        cancelReadySide = nil
        withAnimation(.easeOut(duration: 0.2)) {
            pressProgress = 0
        }
    }

    private func handleScoreTap(side: Side) {
        store.updateRack { r in
            r.result = side == .me ? "won" : "lost"
            if r.outcome == nil { r.outcome = "noRunout" }
            if r.breaker == "none" { r.breaker = side == .me ? "me" : "opp" }
            if r.breakFoul || ![0, 1, 2].contains(r.breakBalls) { r.breakBalls = 1 }
            if r.layout == "none" { r.layout = "open" }
        }
        if store.saveRack() {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
                pulsingSide = side
            }
            Task {
                try? await Task.sleep(nanoseconds: 450_000_000)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    pulsingSide = nil
                }
            }
        }
    }

    private func handleLongPress(side: Side) {
        let result = side == .me ? "won" : "lost"
        if store.removeMostRecentRack(result: result) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    // MARK: left (layout)

    private var layoutColumn: some View {
        VStack(spacing: 5) {
            sectionLabel("Layout")
            layoutChoice("Open", value: "open", color: Theme.green)
            layoutChoice("Cluster", value: "clustered", color: Theme.amber)
            layoutChoice("Problem", value: "problematic", color: Theme.red)
            layoutChoice("Snooked", value: "snookered", color: Theme.purple)
        }
        .padding(.top, 28)
        .padding(.horizontal, 6)
        .padding(.bottom, 10)
    }

    private func layoutChoice(_ label: String, value: String, color: Color) -> some View {
        let isOn = rack.layout == value
        return Button {
            store.updateRack { $0.layout = value }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundColor(isOn ? color : Theme.text2)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .background(isOn ? color.opacity(0.18) : Theme.panel.opacity(0.5))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isOn ? color.opacity(0.45) : Theme.border, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .opacity(isOn ? 1.0 : 0.6)
    }

    // MARK: right (errors)

    private var errorsColumn: some View {
        VStack(spacing: 5) {
            sectionLabel("Errors")
            errorCounter("Miss", count: rack.missCount, color: Theme.teal,
                         inc: { store.updateRack { $0.missCount += 1 } },
                         dec: { store.updateRack { $0.missCount = max(0, $0.missCount - 1) } })
            errorCounter("Position", count: rack.positionTrackingCount, color: Theme.amber,
                         inc: { store.updateRack { $0.badPosition += 1 } },
                         dec: { store.updateRack { $0.badPosition = max(0, $0.badPosition - 1) } })
            errorCounter("Safety", count: rack.safetyCount, color: Theme.blue,
                         inc: { store.updateRack { $0.badSafety += 1 } },
                         dec: { store.updateRack { $0.badSafety = max(0, $0.badSafety - 1) } })
            errorCounter("Pattern", count: rack.patternMistakeCount, color: Theme.purple,
                         inc: { store.updateRack { $0.patternCount += 1 } },
                         dec: { store.updateRack { $0.patternCount = max(0, $0.patternCount - 1) } })
        }
        .padding(.top, 28)
        .padding(.horizontal, 6)
        .padding(.bottom, 10)
    }

    private func errorCounter(_ label: String, count: Int, color: Color, inc: @escaping () -> Void, dec: @escaping () -> Void) -> some View {
        let isActive = count > 0
        return Button {
            inc()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 2) {
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(isActive ? color : Theme.text2)
                Text("\(count)")
                    .font(.callout.weight(.bold).monospacedDigit())
                    .foregroundColor(isActive ? color : Theme.muted)
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .background(isActive ? color.opacity(0.18) : Theme.panel.opacity(0.5))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(isActive ? color.opacity(0.45) : Theme.border, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .opacity(isActive ? 1.0 : 0.6)
        .onLongPressGesture(minimumDuration: 0.4) {
            dec()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(Theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 2)
            .padding(.bottom, 1)
    }

    // MARK: top-center menu dot

    private var menuDot: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                showMenu.toggle()
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Circle()
                .fill(showMenu ? Theme.teal.opacity(0.85) : Theme.muted.opacity(0.45))
                .frame(width: 10, height: 10)
                .padding(10)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: custom menu overlay

    private var customMenuOverlay: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.18)) { showMenu = false }
                }

            VStack(spacing: 0) {
                menuRow(icon: "arrow.uturn.backward", label: "Undo last rack", tint: Theme.text2,
                        disabled: session.racks.isEmpty) {
                    if store.undoLastRack() {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
                menuDivider
                menuRow(
                    icon: showTrackingControls ? "eye.slash" : "eye",
                    label: showTrackingControls ? "Hide tracking" : "Show tracking",
                    tint: Theme.text2
                ) {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        showTrackingControls.toggle()
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                menuDivider
                menuRow(icon: "arrow.down.right.and.arrow.up.left", label: "Exit Lite view", tint: Theme.text2) {
                    onDismiss?()
                }
                menuDivider
                menuRow(icon: "stop.fill", label: "Save & Exit", tint: Theme.red) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showEndConfirm = true
                }
            }
            .frame(width: 240)
            .background(Theme.panel)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.6))
            .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 8)
            .padding(.top, 34)
        }
    }

    private func menuRow(icon: String, label: String, tint: Color, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.18)) { showMenu = false }
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(tint)
                    .frame(width: 18)
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(tint)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1.0)
    }

    private var menuDivider: some View {
        Rectangle()
            .fill(Theme.border)
            .frame(height: 0.5)
    }
}
