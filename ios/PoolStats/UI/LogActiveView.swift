import SwiftUI

struct LogActiveView: View {
    @EnvironmentObject private var store: SessionLogStore
    @Binding var showSaveToast: Bool
    @Binding var showEndConfirm: Bool

    var body: some View {
        if let session = store.currentSession, let rack = store.currentRack {
            VStack(alignment: .leading, spacing: 10) {
                header(session: session, rack: rack)

                if store.sessionStart != nil {
                    LogTimerRow(session: session)
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
            }
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
                    store.updateRack { $0.missEasy += 1 }
                } decrement: {
                    store.updateRack { $0.missEasy = max(0, $0.missEasy - 1) }
                }

                ErrorCounterTile(label: "Positional", value: rack.positionalCount, color: Theme.amber) {
                    store.updateRack { $0.badPosition += 1 }
                } decrement: {
                    store.updateRack { $0.badPosition = max(0, $0.badPosition - 1) }
                }

                ErrorCounterTile(label: "Safety", value: rack.safetyCount, color: Theme.blue) {
                    store.updateRack { $0.badSafety += 1 }
                } decrement: {
                    store.updateRack { $0.badSafety = max(0, $0.badSafety - 1) }
                }

                ErrorCounterTile(label: "Foul", value: rack.foulCount, color: Theme.red) {
                    store.updateRack { $0.fouls += 1 }
                } decrement: {
                    store.updateRack { $0.fouls = max(0, $0.fouls - 1) }
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
            Button("Save rack") {
                if store.saveRack() {
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

            Button("End session") {
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

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1)) { _ in
            let now = Date()
            let sessionElapsed = elapsedSince(store.sessionStart, now: now)
            let rackElapsed = elapsedSince(store.rackStart, now: now)
            let totalRacks = max(session.racks.count, 1)
            let avgPerRack = sessionElapsed / Double(totalRacks)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    timeChip(label: "Session", value: AppFormatters.elapsed(sessionElapsed))
                    timeChip(label: "Rack", value: AppFormatters.elapsed(rackElapsed))
                    timeChip(label: "Avg/rack", value: AppFormatters.elapsed(avgPerRack))
                    Spacer()
                    scoreCard(wins: session.wins, losses: session.losses)
                }
                avgRackBar(seconds: avgPerRack)
            }
        }
    }

    private func elapsedSince(_ start: Date?, now: Date) -> TimeInterval {
        guard let start else { return 0 }
        return max(0, now.timeIntervalSince(start))
    }

    private func timeChip(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(Theme.muted)
            Text(value)
                .font(.caption)
                .foregroundColor(Theme.text)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Theme.panel)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 0.5))
    }

    private func avgRackBar(seconds: TimeInterval) -> some View {
        let target: Double = 60
        let pct = Int(min(100, max(0, seconds / target * 100)))
        return HStack(spacing: 8) {
            Text("Avg pace")
                .font(.caption2)
                .foregroundColor(Theme.muted)
            PercentageBar(value: pct, color: Theme.teal, height: 5)
        }
    }

    private func scoreCard(wins: Int, losses: Int) -> some View {
        HStack(spacing: 0) {
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
    }
}
