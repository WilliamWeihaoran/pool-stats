import SwiftUI

struct LogActiveView: View {
    @EnvironmentObject private var store: DataStore
    @Binding var showSaveToast: Bool
    @Binding var showEndConfirm: Bool

    var body: some View {
        if let session = store.currentSession, let rack = store.currentRack {
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Rack #\(rack.index)")
                            .font(.headline)
                        Spacer()
                        Text(metaText(session))
                            .font(.caption)
                            .foregroundColor(Theme.muted)
                    }

                    if store.sessionStart != nil {
                        LogTimerRow(rackCount: session.racks.count)
                    }
                    sessionStats(session: session)
                }

                LogSectionCard(title: "BREAK") {
                    BreakSection(rack: rack, isPractice: session.isPractice)
                }

                LogSectionCard(title: "Mistakes") {
                    CounterGrid(items: [
                        ("Fouls", "fouls"),
                        ("Safety", "badSafety"),
                        ("Position", "badPosition"),
                        ("Pattern", "planChange")
                    ])
                }

                LogSectionCard(title: "Misses") {
                    HStack(spacing: 8) {
                        MissTile(label: "Easy", key: "missEasy", color: Theme.teal)
                        MissTile(label: "Medium", key: "missMed", color: Theme.amber)
                        MissTile(label: "Hard", key: "missHard", color: Theme.red)
                    }
                }

                LogSectionCard(title: "Result") {
                    ResultSection(rack: rack, session: session)
                }

                ActionRow(rack: rack, isPractice: session.isPractice, showSaveToast: $showSaveToast, showEndConfirm: $showEndConfirm)

                if showSaveToast {
                    Text("Rack saved. Ready for next rack.")
                        .font(.caption2)
                        .foregroundColor(Theme.green)
                        .transition(.opacity)
                }
            }
        } else {
            EmptyView()
        }
    }

    private func sessionStats(session: Session) -> some View {
        let rs = session.racks
        let n = Double(max(rs.count, 1))
        let errors = rs.reduce(0) { $0 + errCount($1) }
        let won = rs.filter { $0.result == "won" }.count
        let runouts = rs.filter { $0.outcome == "runout" }.count

        return HStack(spacing: 10) {
            MiniStatCard(label: "Racks", value: "\(rs.count)")
            if session.isPractice {
                MiniStatCard(label: "Runouts", value: "\(runouts)")
                MiniStatCard(label: "Runout%", value: rs.isEmpty ? "—" : "\(Int(round(Double(runouts) / Double(rs.count) * 100)))%")
            } else {
                MiniStatCard(label: "Won", value: "\(won)")
                MiniStatCard(label: "Win%", value: rs.isEmpty ? "—" : "\(Int(round(Double(won) / Double(rs.count) * 100)))%")
            }
            MiniStatCard(label: "Err/rack", value: rs.isEmpty ? "—" : String(format: "%.1f", Double(errors) / n))
        }
    }

    private func metaText(_ session: Session) -> String {
        let game = session.game == "8ball" ? "8-ball" : "9-ball"
        let type = session.isPractice ? "practice" : "match"
        if !session.isPractice && !session.label.isEmpty {
            return "\(game) \(type) · \(session.label)"
        }
        return "\(game) \(type)"
    }

    private func errCount(_ r: Rack) -> Int {
        r.fouls + r.badSafety + r.badPosition + r.planChange + r.missEasy + r.missMed + r.missHard
    }
}

private struct BreakSection: View {
    @EnvironmentObject private var store: DataStore
    let rack: Rack
    let isPractice: Bool

    var body: some View {
        let breakDisabled = rack.breaker == "none" || rack.breaker == "open"
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Who broke")
                        .font(.caption)
                        .foregroundColor(Theme.text2)
                    HStack(spacing: 8) {
                        BreakRectButton(label: "Me", isOn: rack.breaker == "me", color: Theme.purple) {
                            store.updateRack { $0.breaker = "me" }
                        }
                        BreakRectButton(label: isPractice ? "Open" : "Opp", isOn: rack.breaker == (isPractice ? "open" : "opp"), color: Theme.panel2) {
                            store.updateRack { $0.breaker = isPractice ? "open" : "opp" }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Balls potted")
                        .font(.caption)
                        .foregroundColor(Theme.text2)
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 5)
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach([0, 1, 2, 3], id: \.self) { n in
                            BreakRectButton(label: n == 3 ? "3+" : "\(n)", isOn: rack.breakBalls == n, color: Theme.purple) {
                                store.updateRack { $0.breakBalls = n }
                            }
                            .disabled(breakDisabled)
                            .opacity(breakDisabled ? 0.35 : 1)
                        }
                        BreakRectButton(label: "Foul", isOn: rack.breakFoul, color: Theme.red) {
                            store.updateRack { $0.breakFoul.toggle() }
                        }
                        .disabled(breakDisabled)
                        .opacity(breakDisabled ? 0.35 : 1)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Layout at first visit")
                    .font(.caption)
                    .foregroundColor(Theme.text2)
                HStack(spacing: 8) {
                    BreakLayoutButton(label: "Open", key: "open", isOn: rack.layout == "open", color: Theme.green)
                    BreakLayoutButton(label: "Clustered", key: "clustered", isOn: rack.layout == "clustered", color: Theme.amber)
                    BreakLayoutButton(label: "Problem", key: "problematic", isOn: rack.layout == "problematic", color: Theme.red)
                    BreakLayoutButton(label: "Snookered", key: "snookered", isOn: rack.layout == "snookered", color: Theme.purple)
                }
            }
        }
    }
}

private struct ResultSection: View {
    @EnvironmentObject private var store: DataStore
    let rack: Rack
    let session: Session

    var body: some View {
        if !session.isPractice {
            HStack(spacing: 8) {
                OutcomeResultButton(label: "Won", isOn: rack.result == "won", color: Theme.green) {
                    store.updateRack { $0.result = "won" }
                }
                OutcomeResultButton(label: "Lost", isOn: rack.result == "lost", color: Theme.red) {
                    store.updateRack { $0.result = "lost" }
                }
            }
        }

        VStack(spacing: 6) {
            HStack(spacing: 6) {
                OutcomeTypeButton(label: "Runout", key: "runout", rack: rack, session: session, accent: Theme.teal)
                OutcomeTypeButton(label: "Safety", key: "safety", rack: rack, session: session, accent: Theme.blue)
                OutcomeTypeButton(label: "Error", key: "error", rack: rack, session: session, accent: Theme.red)
                OutcomeTypeButton(label: "Other", key: "other", rack: rack, session: session, accent: Theme.purple)
            }

            if rack.outcome == "runout" && rack.result == "won" {
                HStack {
                    Toggle("Runout first visit", isOn: Binding(
                        get: { rack.runoutFirst },
                        set: { v in store.updateRack { $0.runoutFirst = v } }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: Theme.purple))

                    if rack.breakAndRun {
                        Text("B&R")
                            .font(.caption2)
                            .foregroundColor(Theme.amber)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.panel2)
                            .cornerRadius(4)
                    }
                }
            }
        }
    }
}

private struct ActionRow: View {
    @EnvironmentObject private var store: DataStore
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
        if isPractice { return rack.outcome != nil }
        return rack.result != nil && rack.outcome != nil
    }
}

private struct CounterGrid: View {
    let items: [(String, String)]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 6) {
            ForEach(items, id: \.0) { item in
                CounterTile(label: item.0, key: item.1)
            }
        }
    }
}

private struct CounterTile: View {
    @EnvironmentObject private var store: DataStore
    let label: String
    let key: String

    var body: some View {
        let value = valueForKey(key)
        return VStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(Theme.text2)
            Text("\(value)")
                .font(.title3)
                .foregroundColor(Theme.text)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Theme.panel2)
        .cornerRadius(10)
        .onTapGesture { adjustKey(key, delta: 1) }
        .onLongPressGesture(minimumDuration: 0.5) { adjustKey(key, delta: -1) }
    }

    private func valueForKey(_ key: String) -> Int {
        guard let rack = store.currentRack else { return 0 }
        switch key {
        case "fouls": return rack.fouls
        case "badSafety": return rack.badSafety
        case "badPosition": return rack.badPosition
        case "planChange": return rack.planChange
        case "missEasy": return rack.missEasy
        case "missMed": return rack.missMed
        case "missHard": return rack.missHard
        default: return 0
        }
    }

    private func adjustKey(_ key: String, delta: Int) {
        store.updateRack { r in
            switch key {
            case "fouls": r.fouls = max(0, r.fouls + delta)
            case "badSafety": r.badSafety = max(0, r.badSafety + delta)
            case "badPosition": r.badPosition = max(0, r.badPosition + delta)
            case "planChange": r.planChange = max(0, r.planChange + delta)
            case "missEasy": r.missEasy = max(0, r.missEasy + delta)
            case "missMed": r.missMed = max(0, r.missMed + delta)
            case "missHard": r.missHard = max(0, r.missHard + delta)
            default: break
            }
        }
    }
}

private struct MissTile: View {
    @EnvironmentObject private var store: DataStore
    let label: String
    let key: String
    let color: Color

    var body: some View {
        let value = valueForKey(key)
        return VStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(color)
            Text("\(value)")
                .font(.title3)
                .foregroundColor(Theme.text)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .cornerRadius(10)
        .onTapGesture { adjustKey(key, delta: 1) }
        .onLongPressGesture(minimumDuration: 0.5) { adjustKey(key, delta: -1) }
    }

    private func valueForKey(_ key: String) -> Int {
        guard let rack = store.currentRack else { return 0 }
        switch key {
        case "missEasy": return rack.missEasy
        case "missMed": return rack.missMed
        case "missHard": return rack.missHard
        default: return 0
        }
    }

    private func adjustKey(_ key: String, delta: Int) {
        store.updateRack { r in
            switch key {
            case "missEasy": r.missEasy = max(0, r.missEasy + delta)
            case "missMed": r.missMed = max(0, r.missMed + delta)
            case "missHard": r.missHard = max(0, r.missHard + delta)
            default: break
            }
        }
    }
}

private struct MiniStatCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(Theme.muted)
            Text(value)
                .font(.headline)
                .foregroundColor(Theme.text)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.panel)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
    }
}

private struct BreakRectButton: View {
    let label: String
    let isOn: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.callout)
                .foregroundColor(isOn ? color : Theme.text2)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(isOn ? color.opacity(0.22) : Theme.panel2)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(isOn ? color : Theme.border, lineWidth: 1))
        }
    }
}

private struct BreakLayoutButton: View {
    @EnvironmentObject private var store: DataStore
    let label: String
    let key: String
    let isOn: Bool
    let color: Color

    var body: some View {
        Button(label) {
            store.updateRack { $0.layout = key }
        }
        .font(.caption)
        .foregroundColor(isOn ? color : Theme.text2)
        .frame(maxWidth: .infinity)
        .frame(height: 34)
        .background(color.opacity(isOn ? 0.25 : 0.12))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isOn ? color : Theme.border, lineWidth: 1))
    }
}

private struct LogTimerRow: View {
    @EnvironmentObject private var store: DataStore
    let rackCount: Int

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1)) { _ in
            let now = Date()
            let sessionElapsed = elapsed(from: store.sessionStart, now: now)
            let rackElapsed = elapsed(from: store.rackStart, now: now)
            let totalRacks = max(rackCount, 1)
            let avgPerRack = sessionElapsed / Double(totalRacks)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 12) {
                    timeChip(label: "Session", value: format(sessionElapsed))
                    timeChip(label: "Rack", value: format(rackElapsed))
                    timeChip(label: "Avg/rack", value: format(avgPerRack))
                    Spacer()
                }
                avgRackBar(seconds: avgPerRack)
            }
        }
    }

    private func elapsed(from start: Date?, now: Date) -> TimeInterval {
        guard let start else { return 0 }
        return max(0, now.timeIntervalSince(start))
    }

    private func format(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
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
}

private struct OutcomeResultButton: View {
    let label: String
    let isOn: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.callout)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isOn ? color.opacity(0.22) : Theme.panel2)
                .foregroundColor(isOn ? color : Theme.text2)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isOn ? color : Theme.border, lineWidth: 1))
        }
        .cornerRadius(8)
    }
}

private struct OutcomeTypeButton: View {
    @EnvironmentObject private var store: DataStore
    let label: String
    let key: String
    let rack: Rack
    let session: Session
    let accent: Color

    var body: some View {
        let isOn = rack.outcome == key
        let color: Color = {
            if session.isPractice { return accent }
            if rack.result == "won" { return Theme.green }
            if rack.result == "lost" { return Theme.red }
            return Theme.text2
        }()

        Button(label) {
            store.updateRack { r in
                r.outcome = key
                if key != "runout" {
                    r.runoutFirst = false
                    r.breakAndRun = false
                }
            }
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(isOn ? color.opacity(0.22) : Theme.panel2)
        .foregroundColor(isOn ? color : Theme.text2)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isOn ? color : Theme.border, lineWidth: 1))
        .cornerRadius(8)
    }
}
