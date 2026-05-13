import SwiftUI

struct WatchDrillActiveSessionView: View {
    @EnvironmentObject private var client: WatchConnectivityClient
    @EnvironmentObject private var sessionStore: WatchSessionStore

    let active: ActiveSessionSnapshot

    @State private var difficulty: String = "standard"
    @State private var targetBallCount: Int = 0
    @State private var ballsMade: Double = 0
    @State private var selectedTags: Set<String> = []
    @State private var page: DrillLogPage = .mistakes
    @State private var lastHapticBallsMade: Int = 0

    private let mistakeOptions = ["Potting", "Position", "Pattern", "Runout"]
    private var sessionUUID: String { active.session.sessionUUID }
    private var attempts: Int { active.session.racks.filter { $0.drillOutcome != nil }.count }
    private var successes: Int { active.session.racks.filter { $0.drillOutcome == "success" }.count }
    private var misses: Int { active.session.racks.filter { $0.drillOutcome == "miss" }.count }
    private var canLogSuccess: Bool { Int(ballsMade) >= targetBallCount }
    private var canLogMiss: Bool { Int(ballsMade) < targetBallCount }
    private var title: String { active.session.drillTitle ?? active.session.label }
    private var drillTemplates: [WatchDrillTemplatePayload] {
        if let live = client.snapshot?.availableDrills, !live.isEmpty { return live }
        if !sessionStore.cachedDrills.isEmpty { return sessionStore.cachedDrills }
        return WatchDrillCatalog.fallbackTemplates
    }
    private var selectedTemplate: WatchDrillTemplatePayload? {
        drillTemplates.first(where: { $0.id == active.session.drillID })
    }
    private var countUnit: WatchDrillCountUnit {
        selectedTemplate?.resolvedCountUnit ?? .balls
    }
    private var progressTitle: String {
        countUnit.progressTitle
    }

    var body: some View {
        TabView(selection: $page) {
            mistakesPage.tag(DrillLogPage.mistakes)
            pottedPage.tag(DrillLogPage.potted)
            actionsPage.tag(DrillLogPage.actions)
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .background(Color.black)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            hydrate()
            lastHapticBallsMade = Int(ballsMade)
        }
        .onChange(of: active.session.drillDifficulty) { _, _ in hydrate() }
        .onChange(of: active.session.drillBallCount) { _, _ in hydrate() }
        .onChange(of: Int(ballsMade)) { oldValue, newValue in
            guard newValue != oldValue else { return }
            guard newValue != lastHapticBallsMade else { return }
            lastHapticBallsMade = newValue
            WKInterfaceDevice.current().play(.click)
        }
    }
}

private extension WatchDrillActiveSessionView {
    enum DrillLogPage: Int {
        case mistakes
        case potted
        case actions
    }

    var mistakesPage: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            mistakes
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }

    var pottedPage: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            ballsSlider
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }

    var actionsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                header
                actions
                recentAttempts
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
        }
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)
            HStack(spacing: 5) {
                stat("A", "\(attempts)", .white.opacity(0.72))
                stat("W", "\(successes)", Color(red: 0.37, green: 0.92, blue: 0.83))
                stat("L", "\(misses)", Color(red: 0.97, green: 0.44, blue: 0.44))
            }
        }
    }

    func stat(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: 2) {
            Text(label).font(.system(size: 9, weight: .black))
            Text(value).font(.system(size: 12, weight: .bold).monospacedDigit())
        }
        .foregroundStyle(color)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 9).fill(Color.white.opacity(0.07)))
    }

    var ballsSlider: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(progressTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text("\(Int(ballsMade))/\(targetBallCount)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color(red: 0.98, green: 0.75, blue: 0.25))
            }
            Slider(value: $ballsMade, in: 0...Double(max(targetBallCount, 1)), step: 1)
                .tint(Color(red: 0.98, green: 0.75, blue: 0.25))
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
    }

    var mistakes: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("Mistakes")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                if !selectedTags.isEmpty {
                    Button("Clear") {
                        WKInterfaceDevice.current().play(.click)
                        withAnimation(.spring(response: 0.26, dampingFraction: 0.72)) {
                            selectedTags.removeAll()
                        }
                    }
                    .font(.caption2.weight(.bold))
                    .buttonStyle(WatchLoggingTapStyle())
                }
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(mistakeOptions, id: \.self) { tag in
                    mistakeTagButton(tag)
                }
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
    }

    func mistakeTagButton(_ tag: String) -> some View {
        let selected = selectedTags.contains(tag)
        return Button {
            WKInterfaceDevice.current().play(.click)
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                if selected { selectedTags.remove(tag) } else { selectedTags.insert(tag) }
            }
        } label: {
            Text(tag)
                .font(.caption2.weight(.bold))
                .foregroundStyle(selected ? .black.opacity(0.82) : WatchDrillCatalog.skillColor(tag))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 12).fill(selected ? WatchDrillCatalog.skillColor(tag) : WatchDrillCatalog.skillColor(tag).opacity(0.14)))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selected ? WatchDrillCatalog.skillColor(tag).opacity(0.95) : WatchDrillCatalog.skillColor(tag).opacity(0.26), lineWidth: selected ? 1.2 : 1)
                )
                .shadow(color: selected ? WatchDrillCatalog.skillColor(tag).opacity(0.22) : .clear, radius: 5, y: 2)
                .scaleEffect(selected ? 1.02 : 1)
        }
        .buttonStyle(WatchLoggingTapStyle())
        .animation(.spring(response: 0.26, dampingFraction: 0.68), value: selected)
    }

    var actions: some View {
        VStack(spacing: 7) {
            HStack(spacing: 7) {
                actionButton("Miss", color: Color(red: 0.97, green: 0.44, blue: 0.44), disabled: !canLogMiss) {
                    saveAttempt(outcome: "miss", exit: false)
                }
                actionButton("Success", color: Color(red: 0.37, green: 0.92, blue: 0.83), disabled: !canLogSuccess) {
                    saveAttempt(outcome: "success", exit: false)
                }
            }
            Button {
                saveAttempt(outcome: Int(ballsMade) >= targetBallCount ? "success" : "miss", exit: true)
            } label: {
                Text("Save & Exit")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(red: 0.68, green: 0.54, blue: 0.98))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(red: 0.68, green: 0.54, blue: 0.98).opacity(0.16)))
            }
            .buttonStyle(WatchLoggingTapStyle())
        }
    }

    func actionButton(_ title: String, color: Color, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(disabled ? .white.opacity(0.38) : .black.opacity(0.82))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 15).fill(disabled ? Color.white.opacity(0.08) : color))
        }
        .buttonStyle(WatchLoggingTapStyle())
        .disabled(disabled)
    }

    var recentAttempts: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Recent")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.45))
            ForEach(active.session.racks.suffix(3).reversed(), id: \.id) { rack in
                WatchDrillRecentAttemptRow(rack: rack, targetBallCount: targetBallCount)
            }
        }
    }
}

private extension WatchDrillActiveSessionView {
    func saveAttempt(outcome: String, exit: Bool) {
        let target = targetBallCount
        let made = outcome == "success" ? target : min(Int(ballsMade), max(target - 1, 0))
        let payload = WatchDrillAttemptPayload(
            outcome: outcome,
            tags: Array(selectedTags).sorted(),
            ballsMade: made,
            targetBallCount: target,
            difficulty: difficulty,
            saveAndExit: exit
        )
        WKInterfaceDevice.current().play(outcome == "success" ? .success : .click)
        client.recordDrillAttempt(payload, sessionUUID: sessionUUID)
        if !exit {
            ballsMade = 0
            selectedTags.removeAll()
            lastHapticBallsMade = 0
        }
    }

    func hydrate() {
        difficulty = active.session.drillDifficulty ?? "standard"
        targetBallCount = active.session.drillBallCount ?? WatchDrillCatalog.ballCount(template: selectedTemplate, difficulty: difficulty)
        ballsMade = min(ballsMade, Double(max(targetBallCount, 0)))
    }
}

private struct WatchDrillRecentAttemptRow: View {
    let rack: WatchRack
    let targetBallCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Text("#\(rack.index)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.45))
                Text(rack.drillOutcome == "success" ? "Success" : "Miss")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(outcomeColor)
                Spacer()
                Text("\(rack.drillBallsMade ?? 0)/\(rack.drillTargetBallCount ?? targetBallCount)")
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.72))
            }
            if let tags = rack.drillTags, !tags.isEmpty {
                Text(tags.joined(separator: ", "))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.48))
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 3)
    }

    private var outcomeColor: Color {
        rack.drillOutcome == "success"
            ? Color(red: 0.37, green: 0.92, blue: 0.83)
            : Color(red: 0.97, green: 0.44, blue: 0.44)
    }
}

private struct WatchLoggingTapStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.72), value: configuration.isPressed)
    }
}
