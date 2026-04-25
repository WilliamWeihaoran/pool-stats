import SwiftUI

@main
struct PoolStatsWatchApp: App {
    @StateObject private var client = WatchConnectivityClient()
    @StateObject private var sessionStore = WatchSessionStore()
    @StateObject private var runtime = WatchRuntimeSession()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(client)
                .environmentObject(sessionStore)
                .environmentObject(runtime)
                .task { client.bind(to: sessionStore) }
        }
    }
}

private enum LogSection: Hashable { case breakSection, layout, errors }

// MARK: - Root

private struct WatchRootView: View {
    @EnvironmentObject private var client: WatchConnectivityClient
    @EnvironmentObject private var sessionStore: WatchSessionStore
    @EnvironmentObject private var runtime: WatchRuntimeSession

    @State private var game: String = "8ball"
    @State private var type: String = "match"
    @State private var opponent: String = "Other"
    @State private var finishedSession: WatchSession?

    private var effectiveActive: ActiveSessionSnapshot? {
        client.snapshot?.active ?? sessionStore.activeSnapshot
    }

    private var effectiveDrill: WatchDrillSnapshot? {
        client.snapshot?.activeDrill
    }

    var body: some View {
        NavigationStack {
            Group {
                if let finished = finishedSession {
                    WatchSessionFinishView(
                        session: finished,
                        onSave: { rating in
                            client.endSession(sessionUUID: finished.sessionUUID, rating: rating)
                            finishedSession = nil
                        },
                        onDiscard: {
                            client.discardSession(sessionUUID: finished.sessionUUID)
                            finishedSession = nil
                        }
                    )
                } else if let active = effectiveActive {
                    WatchActiveSessionView(active: active, onRequestFinish: { session in
                        finishedSession = session
                    })
                } else if let drill = effectiveDrill {
                    WatchActiveDrillView(drill: drill)
                } else {
                    WatchSessionStartView(game: $game, type: $type, opponent: $opponent)
                }
            }
            .onAppear {
                client.requestAttach()
                if effectiveActive != nil { runtime.start() }
            }
            .onChange(of: effectiveActive != nil) { _, hasSession in
                if hasSession { runtime.start() } else { runtime.stop() }
            }
        }
    }
}

// MARK: - Active drill

private struct WatchActiveDrillView: View {
    @EnvironmentObject private var client: WatchConnectivityClient
    let drill: WatchDrillSnapshot

    private var successRate: String {
        guard drill.attempts > 0 else { return "--" }
        let pct = Int(round(Double(drill.successes) / Double(drill.attempts) * 100))
        return "\(pct)%"
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Drill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.teal)
                Spacer()
            }

            Text(drill.title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                stat("Try", "\(drill.attempts)", .white.opacity(0.88))
                stat("Good", "\(drill.successes)", .green)
                stat("Rate", successRate, .teal)
            }

            Button {
                client.recordDrillAttempt(runID: drill.runID)
            } label: {
                Text("Attempt")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.18)))
            }
            .buttonStyle(.plain)

            Button {
                client.recordDrillSuccess(runID: drill.runID)
            } label: {
                Text("Success")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.black.opacity(0.86))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.green))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
    }

    private func stat(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 1) {
            Text(label.uppercased())
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white.opacity(0.45))
            Text(value)
                .font(.callout.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.1)))
    }
}

// MARK: - Start session

private struct WatchSessionStartView: View {
    @EnvironmentObject private var client: WatchConnectivityClient

    @Binding var game: String
    @Binding var type: String
    @Binding var opponent: String

    private var opponents: [String] {
        let names = client.snapshot?.availableOpponents ?? ["Other"]
        return names.isEmpty ? ["Other"] : names
    }

    private let typeOptions = [("match", "Match"), ("practice", "Practice")]
    private let gameOptions = [("8ball", "8-ball"), ("9ball", "9-ball")]
    private let cardBackground = Color(red: 0.16, green: 0.16, blue: 0.17)

    private var canStart: Bool {
        !game.isEmpty && !type.isEmpty && !opponent.isEmpty
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Quick Log")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
            }
            cycleRow("Mode", value: $type, options: typeOptions) { modeBadge }
            cycleRow("Game", value: $game, options: gameOptions) { gameBadge }
            cycleRow("Opponent", value: $opponent, options: opponents.map { ($0, $0) }) {
                Text(opponent).font(.footnote.weight(.medium)).foregroundStyle(.teal)
            }
            Button {
                guard canStart else { return }
                client.startSession(game: game, type: type, opponent: opponent)
            } label: {
                Text("Start Session")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(canStart ? Color(red: 0.37, green: 0.92, blue: 0.83) : Color(white: 0.34))
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
            .disabled(!canStart)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
    }

    @ViewBuilder
    private func cycleRow<Accessory: View>(_ label: String, value: Binding<String>, options: [(String, String)], @ViewBuilder accessory: () -> Accessory) -> some View {
        Button {
            let idx = options.firstIndex(where: { $0.0 == value.wrappedValue }) ?? 0
            value.wrappedValue = options[(idx + 1) % options.count].0
        } label: {
            HStack {
                Text(label).font(.footnote).foregroundStyle(.primary)
                Spacer()
                accessory()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(cardBackground))
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var modeBadge: some View {
        Text(type == "match" ? "Match" : "Practice")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(type == "match" ? Color(red: 0.37, green: 0.92, blue: 0.83) : Color(red: 0.68, green: 0.54, blue: 0.98))
    }

    private var gameBadge: some View {
        game == "8ball" ? AnyView(eightBall) : AnyView(nineBall)
    }

    private var eightBall: some View {
        ZStack {
            Circle().fill(Color.black)
            Circle()
                .fill(Color.white)
                .frame(width: 11)
                .overlay(Text("8").font(.system(size: 7, weight: .black)).foregroundStyle(.black))
        }
        .frame(width: 22, height: 22)
    }

    private var nineBall: some View {
        ZStack {
            Circle().fill(Color(red: 0.98, green: 0.82, blue: 0.12))
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.white)
                    .frame(height: geo.size.height * 0.38)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .clipShape(Circle())
            Circle()
                .fill(Color.white)
                .frame(width: 11)
                .overlay(Text("9").font(.system(size: 7, weight: .black)).foregroundStyle(.black))
        }
        .frame(width: 22, height: 22)
    }
}

// MARK: - Active session

private struct WatchActiveSessionView: View {
    @EnvironmentObject private var client: WatchConnectivityClient

    let active: ActiveSessionSnapshot
    let onRequestFinish: (WatchSession) -> Void

    @State private var section: LogSection = .breakSection
    @State private var selectedBreaker: String?
    @State private var selectedBreakBalls: Int = 0
    @State private var breakFoul: Bool = false
    @State private var selectedLayout: String?
    @State private var missCount: Int = 0
    @State private var positionalCount: Int = 0
    @State private var safetyCount: Int = 0
    @State private var foulCount: Int = 0
    @State private var showEndRackSheet: Bool = false
    @State private var pendingFinishAfterRackSave: Bool = false
    @State private var pendingFinishedSession: WatchSession?
    @State private var scoreFlash: ScoreFlash?

    private var rack: WatchRack? { active.rack }
    private var isPractice: Bool { active.session.type == "practice" }
    private var sessionUUID: String { active.session.sessionUUID }
    private struct ScoreFlash: Equatable {
        let wins: Int
        let losses: Int
    }


    var body: some View {
        ZStack {
            TabView(selection: $section) {
                breakView.tag(LogSection.breakSection)
                layoutView.tag(LogSection.layout)
                errorsView.tag(LogSection.errors)
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: section)
            .onAppear {
                hydrateFromRack()
            }
            .onChange(of: showEndRackSheet) { _, showing in
                if !showing && pendingFinishAfterRackSave {
                    pendingFinishAfterRackSave = false
                    onRequestFinish(pendingFinishedSession ?? active.session)
                    pendingFinishedSession = nil
                }
            }
            .onChange(of: rack?.rackUUID) { _, _ in
                hydrateFromRack()
                section = .breakSection
            }

            if let scoreFlash {
                scoreFlashOverlay(scoreFlash)
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .fullScreenCover(isPresented: $showEndRackSheet) {
            EndRackSheet(
                isPractice: isPractice,
                breakerIsMe: selectedBreaker == "me",
                breakQualityBalls: selectedBreakBalls,
                onSaveRack: { result, runout, breakAndRun in
                    let finalPatch = resultPatch(result: result, runout: runout, breakAndRun: breakAndRun)
                    showNextRackFlash(for: result)
                    _ = client.saveRack(sessionUUID: sessionUUID, finalPatch: finalPatch)
                },
                onSaveAndExit: { result, runout, breakAndRun in
                    let finalPatch = resultPatch(result: result, runout: runout, breakAndRun: breakAndRun)
                    pendingFinishedSession = client.saveRack(sessionUUID: sessionUUID, finalPatch: finalPatch)
                    pendingFinishAfterRackSave = true
                }
            )
        }
    }

    // MARK: Section views

    private var breakView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Break")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
            }
            HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                VStack(spacing: 7) {
                    chipButton("Me", selected: selectedBreaker == "me", color: .green) {
                        selectedBreaker = "me"
                        client.patch(.init(breaker: "me"), sessionUUID: sessionUUID)
                    }
                    chipButton("Opp", selected: selectedBreaker == "opp", color: .orange) {
                        selectedBreaker = "opp"
                        client.patch(.init(breaker: "opp"), sessionUUID: sessionUUID)
                    }
                }

                Spacer(minLength: 8)

                Button {
                    breakFoul.toggle()
                    client.patch(.init(breakFoul: breakFoul), sessionUUID: sessionUUID)
                } label: {
                    Text("Foul")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(breakFoul ? Color.black.opacity(0.82) : Self.breakColor(for: 0).opacity(0.72))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(breakFoul ? Self.breakColor(for: 0) : Self.breakColor(for: 0).opacity(0.12))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Self.breakColor(for: 0).opacity(breakFoul ? 0.98 : 0.26), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            ballsSlider
                .frame(width: 62)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 6)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
    }

    private var ballsSlider: some View {
        let currentColor = Self.breakColor(for: selectedBreakBalls)
        let labels: [(Int, String)] = [(3, "3+"), (2, "2"), (1, "1"), (0, "0")]

        return GeometryReader { geo in
            let trackHeight = max(110.0, geo.size.height - 8)
            let knobSize = 30.0
            let usableHeight = max(trackHeight - knobSize, 1)
            let stepHeight = usableHeight / 3.0
            let knobY = -Double(selectedBreakBalls) * stepHeight
            let fillHeight = (Double(selectedBreakBalls) / 3.0 * usableHeight) + knobSize / 2 + 4

            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(currentColor.opacity(0.28), lineWidth: 1)
                    )

                HStack(alignment: .top, spacing: 7) {
                    VStack(spacing: 0) {
                        ForEach(labels, id: \.0) { sliderValue, label in
                            Text(label)
                                .font(.caption2.weight(sliderValue == selectedBreakBalls ? .bold : .semibold))
                                .foregroundStyle(sliderValue == selectedBreakBalls ? Self.breakColor(for: sliderValue).opacity(0.98) : Color.white.opacity(0.28))
                                .frame(maxHeight: .infinity, alignment: .center)
                        }
                    }

                    ZStack(alignment: .bottom) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 12)
                            .padding(.vertical, 4)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [currentColor.opacity(0.55), currentColor],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: 12, height: fillHeight)
                            .padding(.bottom, 4)

                        Circle()
                            .fill(currentColor)
                            .frame(width: knobSize, height: knobSize)
                            .shadow(color: currentColor.opacity(0.35), radius: 8, y: 3)
                            .offset(y: knobY)
                    }
                    .frame(width: 30)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let y = min(max(value.location.y - knobSize / 2, 0), usableHeight)
                        let normalized = 3.0 - (y / usableHeight * 3.0)
                        let newValue = max(0, min(3, Int(normalized.rounded())))
                        guard newValue != selectedBreakBalls else { return }
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.76)) {
                            selectedBreakBalls = newValue
                        }
                        client.patch(.init(breakBalls: newValue), sessionUUID: sessionUUID)
                    }
            )
        }
        .frame(height: 138)
    }

    private static func breakColor(for balls: Int) -> Color {
        switch balls {
        case 0: return Color(red: 0.97, green: 0.44, blue: 0.44)
        case 1: return Color(red: 0.98, green: 0.75, blue: 0.25)
        case 2: return Color(red: 0.38, green: 0.65, blue: 0.98)
        default: return Color(red: 0.37, green: 0.92, blue: 0.83)
        }
    }

    private var layoutView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Layout")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
            }
            VStack(spacing: 6) {
                layoutChip("Open", key: "open", color: Color(red: 0.20, green: 0.86, blue: 0.37))
                layoutChip("Clustered", key: "clustered", color: Color(red: 0.78, green: 0.62, blue: 0.10))
                layoutChip("Problem", key: "problematic", color: Color(red: 0.73, green: 0.35, blue: 0.38))
                layoutChip("Snookered", key: "snookered", color: Color(red: 0.66, green: 0.50, blue: 0.98))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 6)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
    }

    private static let missColor     = Color(red: 0.37, green: 0.92, blue: 0.83)
    private static let positionColor = Color(red: 0.98, green: 0.75, blue: 0.25)
    private static let safetyColor   = Color(red: 0.38, green: 0.65, blue: 0.98)
    private static let foulColor     = Color(red: 0.97, green: 0.44, blue: 0.44)

    @ViewBuilder
    private func scoreFlashOverlay(_ flash: ScoreFlash) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 4) {
                Text("Score")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .kerning(1.2)

                HStack(alignment: .center, spacing: 0) {
                    VStack(spacing: 2) {
                        Text("\(flash.wins)")
                            .font(.system(size: 64, weight: .black, design: .rounded).monospacedDigit())
                            .foregroundStyle(Color(red: 0.37, green: 0.92, blue: 0.83))
                        Text("Me")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color(red: 0.37, green: 0.92, blue: 0.83).opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)

                    Text("–")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(.white.opacity(0.3))

                    VStack(spacing: 2) {
                        Text("\(flash.losses)")
                            .font(.system(size: 64, weight: .black, design: .rounded).monospacedDigit())
                            .foregroundStyle(Color(red: 0.97, green: 0.44, blue: 0.44))
                        Text("Opp")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color(red: 0.97, green: 0.44, blue: 0.44).opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                }

                Text("Tap to continue")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.28))
                    .padding(.top, 4)
            }
            .padding(.horizontal, 12)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.18)) {
                scoreFlash = nil
            }
        }
    }

    private func showNextRackFlash(for result: String?) {
        let addedWin = result == "won" ? 1 : 0
        let addedLoss = result == "lost" ? 1 : 0
        let flash = ScoreFlash(wins: active.session.wins + addedWin, losses: active.session.losses + addedLoss)
        withAnimation(.easeIn(duration: 0.15)) {
            scoreFlash = flash
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                if scoreFlash == flash {
                    scoreFlash = nil
                }
            }
        }
    }

    private var errorsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Errors")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
            }

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    errorTile("Miss", count: missCount, color: Self.missColor) { d in
                        missCount = max(0, missCount + d)
                        client.patch(.init(missCount: missCount), sessionUUID: sessionUUID)
                    }
                    errorTile("Position", count: positionalCount, color: Self.positionColor) { d in
                        positionalCount = max(0, positionalCount + d)
                        client.patch(.init(badPosition: positionalCount), sessionUUID: sessionUUID)
                    }
                }

                HStack(spacing: 6) {
                    errorTile("Safety", count: safetyCount, color: Self.safetyColor) { d in
                        safetyCount = max(0, safetyCount + d)
                        client.patch(.init(badSafety: safetyCount), sessionUUID: sessionUUID)
                    }
                    errorTile("Foul", count: foulCount, color: Self.foulColor) { d in
                        foulCount = max(0, foulCount + d)
                        client.patch(.init(fouls: foulCount), sessionUUID: sessionUUID)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            Button {
                showEndRackSheet = true
            } label: {
                Text("End Rack")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 24)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color(red: 0.97, green: 0.44, blue: 0.44))
                    )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 6)
        .padding(.top, 0)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
    }

    // MARK: Helpers

    private func resultPatch(result: String?, runout: Bool, breakAndRun: Bool) -> WatchRackPatch? {
        guard let result else { return nil }
        let outcome = result == "won" ? (runout ? "runout" : "noRunout") : "noRunout"
        return .init(result: result, outcome: outcome, runoutFirst: runout, breakAndRun: breakAndRun)
    }

    private func hydrateFromRack() {
        guard let rack else { return }
        selectedBreaker = ["me", "opp"].contains(rack.breaker) ? rack.breaker : nil
        selectedBreakBalls = rack.breakBalls >= 0 ? min(max(rack.breakBalls, 0), 3) : 0
        breakFoul = rack.breakFoul
        let fresh = rack.breaker == "none" && rack.breakBalls < 0 && rack.result == nil
            && rack.fouls == 0 && rack.badSafety == 0 && rack.badPosition == 0 && rack.missCount == 0
        selectedLayout = fresh ? nil : rack.layout
        missCount = rack.missCount
        positionalCount = rack.badPosition
        safetyCount = rack.badSafety
        foulCount = rack.fouls

        if selectedBreaker == nil {
            section = .breakSection
        } else if selectedLayout == nil {
            section = .layout
        } else {
            section = .errors
        }
    }

    @ViewBuilder
    private func errorTile(_ title: String, count: Int, color: Color, change: @escaping (Int) -> Void) -> some View {
        let active = count > 0
        VStack(spacing: 1) {
            Text("\(count)")
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(active ? color : .secondary)
                .contentTransition(.numericText())
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(active ? color.opacity(0.9) : Color.secondary.opacity(0.5))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(RoundedRectangle(cornerRadius: 10).fill(active ? color.opacity(0.15) : Color(white: 0.1)))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(active ? color.opacity(0.5) : Color(white: 0.18), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    guard count > 0 else { return }
                    change(-1)
                }
        )
        .onTapGesture {
            change(1)
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.6), value: count)
    }

    @ViewBuilder
    private func chipButton(_ title: String, selected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(selected ? Color.black.opacity(0.82) : color.opacity(0.98))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(selected ? color : color.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(selected ? color.opacity(0.98) : color.opacity(0.28), lineWidth: selected ? 1.5 : 1)
                )
                .shadow(color: selected ? color.opacity(0.26) : .clear, radius: 8, y: 3)
                .scaleEffect(selected ? 1.04 : 1)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.26, dampingFraction: 0.72), value: selected)
    }

    @ViewBuilder
    private func layoutChip(_ title: String, key: String, color: Color) -> some View {
        let selected = selectedLayout == key
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                selectedLayout = key
            }
            client.patch(.init(layout: key), sessionUUID: sessionUUID)
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(selected ? Color.black.opacity(0.82) : color.opacity(0.72))
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(selected ? color : color.opacity(0.14))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(selected ? color.opacity(0.96) : color.opacity(0.24), lineWidth: selected ? 1.5 : 1)
                )
                .shadow(color: selected ? color.opacity(0.22) : .clear, radius: 7, y: 3)
                .scaleEffect(selected ? 1.02 : 1)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.26, dampingFraction: 0.68), value: selected)
    }

}

// MARK: - End rack sheet

private struct EndRackSheet: View {
    @Environment(\.dismiss) private var dismiss

    let isPractice: Bool
    let breakerIsMe: Bool
    let breakQualityBalls: Int
    let onSaveRack: (String?, Bool, Bool) -> Void
    let onSaveAndExit: (String?, Bool, Bool) -> Void

    @State private var selectedResult: String? = nil
    @State private var runoutFirst: Bool = false

    private var canSave: Bool { isPractice || selectedResult != nil }
    private var breakAndRun: Bool { runoutFirst && breakerIsMe && breakQualityBalls >= 1 }
    private var runoutEnabled: Bool { selectedResult == "won" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 7) {
                    if !isPractice {
                        HStack(spacing: 7) {
                            resultButton("Won", selected: selectedResult == "won", color: .green) {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                    selectedResult = "won"
                                }
                            }
                            resultButton("Lost", selected: selectedResult == "lost", color: .red) {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                    selectedResult = "lost"
                                    runoutFirst = false
                                }
                            }
                        }

                        runoutCard
                    }

                    VStack(spacing: 7) {
                        actionButton("Next Rack", color: .teal, prominent: true, disabled: !canSave) {
                            onSaveRack(selectedResult, runoutFirst, breakAndRun)
                            dismiss()
                        }

                        actionButton("Save & Exit", color: .red, prominent: false, disabled: !canSave) {
                            onSaveAndExit(selectedResult, runoutFirst, breakAndRun)
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
            .navigationTitle(isPractice ? "Finish Rack" : "Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .background(
                Color.black.ignoresSafeArea()
            )
        }
    }

    @ViewBuilder
    private var runoutCard: some View {
        Button {
            guard runoutEnabled else { return }
            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                runoutFirst.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Text("Runout")
                    .font(.caption.weight(.semibold))
                Spacer()
                Image(systemName: runoutFirst ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
            }
            .foregroundStyle(runoutEnabled ? (runoutFirst ? Color.black.opacity(0.82) : Color.yellow.opacity(0.95)) : Color.secondary.opacity(0.55))
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(runoutFirst ? Color.yellow : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(runoutEnabled ? Color.yellow.opacity(runoutFirst ? 0.95 : 0.28) : Color.white.opacity(0.08), lineWidth: 1)
            )
            .opacity(runoutEnabled ? 1 : 0.72)
            .scaleEffect(runoutFirst ? 1.02 : 1)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func resultButton(_ title: String, selected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(selected ? Color.black.opacity(0.84) : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(selected ? color : Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(selected ? color.opacity(0.95) : Color.white.opacity(0.09), lineWidth: 1)
                )
                .scaleEffect(selected ? 1.03 : 1)
                .shadow(color: selected ? color.opacity(0.28) : .clear, radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func actionButton(_ title: String, color: Color, prominent: Bool, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(prominent ? .headline.weight(.semibold) : .subheadline.weight(.semibold))
                .foregroundStyle(prominent || disabled ? .white : color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, prominent ? 8 : 6)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            disabled ? Color(white: 0.24) :
                                (prominent ? color : color.opacity(0.16))
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(disabled ? Color.clear : color.opacity(prominent ? 0 : 0.4), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.72 : 1)
    }
}

// MARK: - Finish session

private struct WatchSessionFinishView: View {
    let session: WatchSession
    let onSave: (Int) -> Void
    let onDiscard: () -> Void

    @State private var rating: Double = 7

    // MARK: Computed stats

    private var durationText: String {
        guard let d = session.durationSeconds, d > 0 else { return "--" }
        let m = d / 60
        return m > 0 ? "\(m)m" : "<1m"
    }

    private var winRateText: String? {
        let total = session.wins + session.losses
        guard total > 0, !session.isPractice else { return nil }
        return "\(Int(round(Double(session.wins) / Double(total) * 100)))%"
    }

    private var avgBreakBalls: String {
        let valid = session.racks.filter { $0.breakBalls >= 0 }
        guard !valid.isEmpty else { return "--" }
        let avg = Double(valid.map(\.breakBalls).reduce(0, +)) / Double(valid.count)
        return String(format: "%.1f", avg)
    }

    private var totalErrors: Int {
        session.racks.reduce(0) { $0 + $1.missCount + $1.badPosition + $1.badSafety + $1.fouls }
    }

    private var ratingColor: Color {
        switch Int(rating) {
        case 1...3: .red
        case 4...6: .orange
        case 7...8: .yellow
        default: .green
        }
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Inline title + score header
                HStack(alignment: .firstTextBaseline) {
                    Text("Summary")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                    if !session.isPractice {
                        HStack(spacing: 4) {
                            Text("\(session.wins)")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.green)
                            Text("–")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white.opacity(0.4))
                            Text("\(session.losses)")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.red)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Stats tiles
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 5) {
                    summaryTile("Duration", durationText, color: .white)
                    if let wr = winRateText { summaryTile("Win Rate", wr, color: .green) }
                    summaryTile("Avg Break", avgBreakBalls, color: Color(red: 0.98, green: 0.75, blue: 0.25))
                    summaryTile("Errors", "\(totalErrors)", color: totalErrors > 0 ? .orange : Color.white.opacity(0.5))
                }

                // Drag rating control
                VStack(spacing: 6) {
                    HStack {
                        Text("Rating")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.8))
                        Spacer()
                        Text("\(Int(rating))/10")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(ratingColor)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: rating)
                    }
                    GeometryReader { geo in
                        let barWidth = geo.size.width
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.12))
                                .frame(height: 20)
                            Capsule()
                                .fill(ratingColor.opacity(0.85))
                                .frame(width: max(0, barWidth * (rating - 1) / 9.0), height: 20)
                            Text("\(Int(rating))")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let pct = max(0, min(1, value.location.x / barWidth))
                                    let newRating = (pct * 9.0 + 1).rounded()
                                    let clamped = max(1, min(10, newRating))
                                    if clamped != rating {
                                        rating = clamped
                                        WKInterfaceDevice.current().play(.click)
                                    }
                                }
                        )
                    }
                    .frame(height: 20)
                }

                // Actions
                HStack(spacing: 6) {
                    Button("Save") { onSave(Int(rating)) }
                        .buttonStyle(.borderedProminent)
                        .tint(.teal)
                        .frame(maxWidth: .infinity)
                    Button("Discard") { onDiscard() }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .navigationBarBackButtonHidden(true)
    }

    @ViewBuilder
    private func summaryTile(_ label: String, _ value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.callout.weight(.bold).monospacedDigit())
                .foregroundStyle(color)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.48))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.07)))
    }
}
