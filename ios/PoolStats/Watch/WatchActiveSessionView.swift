import SwiftUI

struct WatchActiveSessionView: View {
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
    @State private var patternCount: Int = 0
    @State private var showEndRackSheet: Bool = false
    @State private var scoreFlash: WatchMatchScoreFlash?
    @State private var hasRestoredSheetState = false
    @State private var isFinishingSession = false

    private static let endRackSheetSessionKey = "poolstats.watch.endrack.session.v1"

    private var rack: WatchRack? { active.rack }
    private var isPractice: Bool { active.session.type == "practice" }
    private var sessionUUID: String { active.session.sessionUUID }
    private var effectiveBreaker: String {
        WatchSyncReconciler.displayedBreakerValue(selectedBreaker)
    }

    private var sectionName: String {
        switch section {
        case .breakSection: return "Break"
        case .layout: return "Layout"
        case .errors: return "Errors"
        }
    }

    // MARK: - Colors

    private static let missColor     = Color(red: 0.37, green: 0.92, blue: 0.83)
    private static let positionColor = Color(red: 0.98, green: 0.75, blue: 0.25)
    private static let safetyColor   = Color(red: 0.38, green: 0.65, blue: 0.98)
    private static let patternColor  = Color(red: 0.66, green: 0.50, blue: 0.98)

    private static func breakColor(for balls: Int) -> Color {
        switch balls {
        case 0: return Color(red: 0.97, green: 0.44, blue: 0.44)
        case 1: return Color(red: 0.98, green: 0.75, blue: 0.25)
        case 2: return Color(red: 0.38, green: 0.65, blue: 0.98)
        default: return Color(red: 0.37, green: 0.92, blue: 0.83)
        }
    }

    // MARK: - Body

    var body: some View {
        if active.session.isDrillPractice {
            WatchDrillActiveSessionView(active: active)
        } else {
            ZStack {
            TabView(selection: $section) {
                breakView.tag(LogSection.breakSection)
                layoutView.tag(LogSection.layout)
                errorsView.tag(LogSection.errors)
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: section)
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { hydrateFromRack() }
            .onChange(of: rack?.rackUUID) { _, _ in
                hydrateFromRack()
                section = .breakSection
                UserDefaults.standard.removeObject(forKey: Self.endRackSheetSessionKey)
            }
            .allowsHitTesting(!isFinishingSession)

            if let scoreFlash {
                WatchMatchScoreFlashView(flash: scoreFlash) {
                    withAnimation(.easeOut(duration: 0.18)) { self.scoreFlash = nil }
                }
                    .transition(.opacity)
                    .zIndex(10)
            }

            if isFinishingSession {
                Color.black
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(12)
            }

            if showEndRackSheet {
                EndRackSheet(
                    isPractice: isPractice,
                    breakerIsMe: effectiveBreaker == "me",
                    breakQualityBalls: selectedBreakBalls,
                    onSaveRack: { result, runout, breakAndRun in
                        let patch = resultPatch(result: result, runout: runout, breakAndRun: breakAndRun)
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            showEndRackSheet = false
                        }
                        showNextRackFlash(for: result)
                        client.saveRack(sessionUUID: sessionUUID, patch: patch)
                    },
                    onSaveAndExit: { result, runout, breakAndRun in
                        guard !isFinishingSession else { return }
                        isFinishingSession = true
                        let patch = resultPatch(result: result, runout: runout, breakAndRun: breakAndRun)
                        client.saveRack(sessionUUID: sessionUUID, patch: patch)
                        let finished = finishedSession(result: result, runout: runout, breakAndRun: breakAndRun)
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            showEndRackSheet = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            onRequestFinish(finished)
                        }
                    },
                    onClose: {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            showEndRackSheet = false
                        }
                    }
                )
                .transition(.move(edge: .bottom))
                .zIndex(5)
            }
        }
        .onAppear { restoreSheetStateIfNeeded() }
        .onChange(of: showEndRackSheet) { _, newVal in
            if newVal {
                UserDefaults.standard.set(sessionUUID, forKey: Self.endRackSheetSessionKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.endRackSheetSessionKey)
            }
        }
        }
    }

    // MARK: - Section views

    private var breakView: some View {
        VStack(alignment: .leading, spacing: 4) {
            pageHeader("Break")
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Button {
                        WKInterfaceDevice.current().play(.click)
                        selectedBreaker = effectiveBreaker == "opp" ? "me" : "opp"
                        client.patch(.init(breaker: selectedBreaker), sessionUUID: sessionUUID)
                    } label: {
                        let isMe = effectiveBreaker == "me"
                        Text(isMe ? "Me" : "Opp")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(isMe ? Color.green : Color.orange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill((isMe ? Color.green : Color.orange).opacity(0.18))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke((isMe ? Color.green : Color.orange).opacity(0.5), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 8)

                    Button {
                        WKInterfaceDevice.current().play(.click)
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

                ballsSlider.frame(width: 62)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 6)
    }

    private var ballsSlider: some View {
        let currentColor = Self.breakColor(for: selectedBreakBalls)
        let labels: [(Int, String)] = [(3, "3+"), (2, "2"), (1, "1"), (0, "0")]

        return GeometryReader { geo in
            let trackHeight = max(110.0, geo.size.height - 8)
            let knobSize = 30.0
            let usableHeight = max(trackHeight - knobSize, 1)
            let knobY = -Double(selectedBreakBalls) * (usableHeight / 3.0)
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
                                .foregroundStyle(sliderValue == selectedBreakBalls
                                    ? Self.breakColor(for: sliderValue).opacity(0.98)
                                    : Color.white.opacity(0.28))
                                .frame(maxHeight: .infinity, alignment: .center)
                        }
                    }

                    ZStack(alignment: .bottom) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 12)
                            .padding(.vertical, 4)

                        Capsule()
                            .fill(LinearGradient(
                                colors: [currentColor.opacity(0.55), currentColor],
                                startPoint: .bottom, endPoint: .top
                            ))
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
                        WKInterfaceDevice.current().play(.click)
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.76)) {
                            selectedBreakBalls = newValue
                        }
                        client.patch(.init(breakBalls: newValue), sessionUUID: sessionUUID)
                    }
            )
        }
        .frame(height: 138)
    }

    private var layoutView: some View {
        VStack(alignment: .leading, spacing: 4) {
            pageHeader("Layout")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                layoutChip("Open",      key: "open",        color: Color(red: 0.20, green: 0.86, blue: 0.37))
                layoutChip("Clustered", key: "clustered",   color: Color(red: 0.78, green: 0.62, blue: 0.10))
                layoutChip("Problem",   key: "problematic", color: Color(red: 0.73, green: 0.35, blue: 0.38))
                layoutChip("Snookered", key: "snookered",   color: Color(red: 0.66, green: 0.50, blue: 0.98))
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 6)
    }

    private var errorsView: some View {
        VStack(alignment: .leading, spacing: 3) {
            pageHeader("Errors")
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    errorTile("Miss",     count: missCount,       color: Self.missColor)     { d in missCount       = max(0, missCount + d);       client.patch(.init(missCount: missCount),             sessionUUID: sessionUUID) }
                    errorTile("Position", count: positionalCount, color: Self.positionColor) { d in positionalCount = max(0, positionalCount + d); client.patch(.init(badPosition: positionalCount),     sessionUUID: sessionUUID) }
                }
                HStack(spacing: 6) {
                    errorTile("Safety",   count: safetyCount,     color: Self.safetyColor)   { d in safetyCount     = max(0, safetyCount + d);     client.patch(.init(badSafety: safetyCount),           sessionUUID: sessionUUID) }
                    errorTile("Pattern",  count: patternCount,    color: Self.patternColor)  { d in patternCount    = max(0, patternCount + d);    client.patch(.init(patternCount: patternCount),         sessionUUID: sessionUUID) }
                }
            }

            Spacer(minLength: 2)

            Button {
                WKInterfaceDevice.current().play(.click)
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    showEndRackSheet = true
                }
            } label: {
                Text("End Rack")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 22)
                    .background(Capsule(style: .continuous).fill(Color(red: 0.97, green: 0.44, blue: 0.44)))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
            .padding(.bottom, 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 6)
    }

    private func showNextRackFlash(for result: String?) {
        let rackSeconds: Int? = active.rackStartedAt.flatMap { start in
            let buffered = Int(Date().timeIntervalSince(start)) - 45
            return buffered > 0 ? buffered : nil
        }
        let flash = WatchMatchScoreFlash(
            wins: active.session.wins + (result == "won" ? 1 : 0),
            losses: active.session.losses + (result == "lost" ? 1 : 0),
            rackSeconds: rackSeconds
        )
        WKInterfaceDevice.current().play(.success)
        withAnimation(.easeIn(duration: 0.15)) { scoreFlash = flash }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                if scoreFlash == flash { scoreFlash = nil }
            }
        }
    }

    // MARK: - Helpers

    private func resultPatch(result: String?, runout: Bool, breakAndRun: Bool) -> WatchRackPatch? {
        guard let result else { return nil }
        let outcome = result == "won" ? (runout ? "runout" : "noRunout") : "noRunout"
        return .init(
            result: result,
            breaker: effectiveBreaker,
            breakBalls: selectedBreakBalls,
            breakFoul: breakFoul,
            layout: selectedLayout,
            outcome: outcome,
            fouls: rack?.fouls,
            badSafety: safetyCount,
            badPosition: positionalCount,
            patternCount: patternCount,
            missCount: missCount,
            runoutFirst: runout,
            breakAndRun: breakAndRun
        )
    }

    private func hydrateFromRack() {
        guard let rack else { return }
        selectedBreaker = ["me", "opp"].contains(rack.breaker) ? rack.breaker : nil
        selectedBreakBalls = rack.breakBalls >= 0 ? min(max(rack.breakBalls, 0), 3) : 0
        breakFoul = rack.breakFoul
        let fresh = rack.breaker == "none" && rack.breakBalls < 0 && rack.result == nil
            && rack.fouls == 0 && rack.badSafety == 0 && rack.badPosition == 0 && rack.patternCount == 0 && rack.missCount == 0
        selectedLayout = fresh ? nil : rack.layout
        missCount = rack.missCount
        positionalCount = rack.badPosition
        safetyCount = rack.badSafety
        patternCount = rack.patternCount

        if selectedBreaker == nil { section = .breakSection }
        else if selectedLayout == nil { section = .layout }
        else { section = .errors }
    }

    private func finishedSession(result: String?, runout: Bool, breakAndRun: Bool) -> WatchSession {
        var session = active.session
        guard var finalRack = rack else { return session }
        if let result {
            finalRack.result = result
            finalRack.breaker = effectiveBreaker
            finalRack.breakBalls = selectedBreakBalls
            finalRack.breakFoul = breakFoul
            finalRack.outcome = result == "won" ? (runout ? "runout" : "noRunout") : "noRunout"
            finalRack.runoutFirst = runout
            finalRack.breakAndRun = breakAndRun
        }
        session.racks.append(finalRack)
        return session
    }

    private func restoreSheetStateIfNeeded() {
        guard !hasRestoredSheetState else { return }
        hasRestoredSheetState = true
        let stored = UserDefaults.standard.string(forKey: Self.endRackSheetSessionKey)
        guard stored == sessionUUID else { return }
        showEndRackSheet = true
    }

    @ViewBuilder
    private func pageHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
            Text("Rack \(rack?.index ?? active.session.racks.count + 1)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(.bottom, 2)
    }

    // MARK: - Reusable sub-components

    @ViewBuilder
    private func errorTile(_ title: String, count: Int, color: Color, change: @escaping (Int) -> Void) -> some View {
        let isActive = count > 0
        VStack(spacing: 1) {
            Text("\(count)")
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(isActive ? color : Color.secondary)
                .contentTransition(.numericText())
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(color.opacity(0.85))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(RoundedRectangle(cornerRadius: 10).fill(isActive ? color.opacity(0.15) : Color(white: 0.1)))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(isActive ? color.opacity(0.5) : Color(white: 0.18), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    guard count > 0 else { return }
                    WKInterfaceDevice.current().play(.directionDown)
                    change(-1)
                }
        )
        .onTapGesture {
            WKInterfaceDevice.current().play(.click)
            change(1)
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.6), value: count)
    }

    @ViewBuilder
    private func layoutChip(_ title: String, key: String, color: Color) -> some View {
        let selected = selectedLayout == key
        Button {
            WKInterfaceDevice.current().play(.click)
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) { selectedLayout = key }
            client.patch(.init(layout: key), sessionUUID: sessionUUID)
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(selected ? Color.black.opacity(0.82) : color.opacity(0.72))
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
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
