import SwiftUI

struct OpponentManagementView: View {
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var opponentStore: OpponentStore
    @State private var selectedOpponentID: UUID?
    @State private var editorMode: OpponentEditorMode?
    @State private var deleteTarget: OpponentProfile?

    var body: some View {
        VStack(spacing: 14) {
            overviewSection
            opponentsSection
            headToHeadSection
        }
        .task {
            opponentStore.sync(with: store.sessions)
            if selectedOpponentID == nil {
                selectedOpponentID = opponentStore.profiles.first?.id
            }
        }
        .sheet(item: $editorMode) { mode in
            OpponentEditorSheet(mode: mode) { name in
                switch mode {
                case .add:
                    opponentStore.addOpponent(name: name)
                case .edit(let profile):
                    opponentStore.updateOpponent(id: profile.id, displayName: name)
                    if selectedOpponentID == profile.id {
                        selectedOpponentID = profile.id
                    }
                }
            }
        }
        .alert("Delete opponent?", isPresented: Binding(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let target = deleteTarget {
                    if selectedOpponentID == target.id {
                        selectedOpponentID = opponentStore.profiles.first(where: { $0.id != target.id })?.id
                    }
                    opponentStore.deleteOpponent(id: target.id)
                }
                deleteTarget = nil
            }
            Button("Cancel", role: .cancel) {
                deleteTarget = nil
            }
        } message: {
            Text("This removes the opponent from the list. Historical sessions stay intact.")
        }
    }

    private var overviewSection: some View {
        let favorites = opponentStore.profiles.filter(\.isFavorite).count
        return LazyVGrid(columns: Layout.twoColumn(), spacing: Layout.gridSpacing) {
            StatCard(label: "Opponents", value: "\(opponentStore.profiles.count)")
            StatCard(label: "Favorites", value: "\(favorites)")
        }
    }

    private var opponentsSection: some View {
        SectionCard(title: "Opponents") {
            VStack(spacing: 10) {
                HStack {
                    Text("Manage your list")
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                    Spacer()
                    Button {
                        editorMode = .add
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("Add opponent")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.text)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.panel2)
                        .cornerRadius(9)
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Theme.border, lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }

                if opponentStore.profiles.isEmpty {
                    Text("Add opponents to track head-to-head stats and favorites.")
                        .font(.caption)
                        .foregroundColor(Theme.text2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 8) {
                        ForEach(opponentStore.profiles) { profile in
                            OpponentRow(
                                profile: profile,
                                isSelected: selectedOpponentID == profile.id,
                                lastSeenText: AppFormatters.sessionDate(profile.lastSeenAt),
                                actionSelect: {
                                    selectedOpponentID = profile.id
                                },
                                actionFavorite: {
                                    opponentStore.toggleFavorite(id: profile.id)
                                },
                                actionEdit: {
                                    editorMode = .edit(profile)
                                },
                                actionDelete: {
                                    deleteTarget = profile
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    private var selectedOpponent: OpponentProfile? {
        guard let selectedOpponentID else { return opponentStore.profiles.first }
        return opponentStore.profiles.first(where: { $0.id == selectedOpponentID }) ?? opponentStore.profiles.first
    }

    private var headToHeadSection: some View {
        Group {
            if let profile = selectedOpponent {
                let h2h = opponentStore.headToHead(for: profile.displayName, sessions: store.sessions)
                let opponentMatchSessions = store.sessions.filter {
                    $0.type == "match" && opponentStore.matches($0.opponent, selected: profile.displayName)
                }
                let opponentMatchRacks = Analytics.matchRacks(opponentMatchSessions)
                SectionCard(title: "Head to head") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.displayName)
                                    .font(.headline)
                                    .foregroundColor(Theme.text)
                                Text(profile.isFavorite ? "Favorite opponent" : "Selected opponent")
                                    .font(.caption2)
                                    .foregroundColor(Theme.text2)
                            }
                            Spacer(minLength: 0)
                            if profile.isFavorite {
                                Image(systemName: "star.fill")
                                    .foregroundColor(Theme.amber)
                            }
                        }

                        LazyVGrid(columns: Layout.twoColumn(), spacing: Layout.gridSpacing) {
                            StatCard(label: "Sessions", value: "\(h2h.sessions)")
                            StatCard(label: "Session win%", value: h2h.sessionWinRate)
                            StatCard(label: "Rack win%", value: h2h.rackWinRate)
                            StatCard(label: "Avg rating", value: h2h.averageRating)
                        }

                        HStack {
                            Text("Last played")
                                .font(.caption2)
                                .foregroundColor(Theme.text2)
                            Spacer()
                            Text(h2h.lastPlayed)
                                .font(.caption.weight(.medium))
                                .foregroundColor(Theme.text)
                        }

                        Divider()
                            .overlay(Theme.border)

                        HStack(spacing: 14) {
                            RingChart(wins: h2h.sessionWins, losses: h2h.sessionLosses)
                                .frame(maxWidth: 140)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Session outcomes")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(Theme.text2)
                                Text("Wins (\(h2h.sessionWins))")
                                    .font(.caption)
                                    .foregroundColor(Theme.teal)
                                Text("Losses (\(h2h.sessionLosses))")
                                    .font(.caption)
                                    .foregroundColor(Theme.red)
                            }
                            Spacer(minLength: 0)
                        }

                        // Session W/L history
                        let sortedSessions = opponentMatchSessions.sorted { $0.ts < $1.ts }
                        if !sortedSessions.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Session history")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(Theme.text2)
                                SessionHistoryStrip(sessions: sortedSessions)
                            }
                        }

                        // Break advantage
                        if !opponentMatchRacks.isEmpty {
                            let myBreakRacks = opponentMatchRacks.filter { $0.breaker == "me" }
                            let oppBreakRacks = opponentMatchRacks.filter { $0.breaker == "opp" }
                            let myBreakWins = myBreakRacks.filter { $0.result == "won" }.count
                            let oppBreakWins = oppBreakRacks.filter { $0.result == "won" }.count
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Break advantage")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(Theme.text2)
                                BreakAdvantageRow(label: "You broke", wins: myBreakWins, total: myBreakRacks.count)
                                BreakAdvantageRow(label: "Opp broke", wins: oppBreakWins, total: oppBreakRacks.count)
                            }
                        }
                    }
                }
            } else {
                SectionCard(title: "Head to head") {
                    Text("Select an opponent to see the matchup.")
                        .font(.caption)
                        .foregroundColor(Theme.text2)
                }
            }
        }
    }

}

private struct SessionHistoryStrip: View {
    let sessions: [Session]

    private var streak: (label: String, color: Color) {
        var count = 0
        let reversed = sessions.reversed()
        guard let first = reversed.first else { return ("—", Theme.muted) }
        let firstWon = first.wins > first.racks.count / 2
        for s in reversed {
            let won = s.wins > s.racks.count / 2
            if won == firstWon { count += 1 } else { break }
        }
        return firstWon
            ? ("W\(count)", Theme.green)
            : ("L\(count)", Theme.red)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    ForEach(Array(sessions.enumerated()), id: \.offset) { _, session in
                        let won = session.wins > session.racks.count / 2
                        RoundedRectangle(cornerRadius: 4)
                            .fill(won ? Theme.green : Theme.red)
                            .frame(width: 18, height: 28)
                    }
                }
            }
            HStack(spacing: 6) {
                Text("Streak")
                    .font(.caption2)
                    .foregroundColor(Theme.muted)
                Text(streak.label)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(streak.color)
                Spacer()
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2).fill(Theme.green).frame(width: 10, height: 10)
                    Text("W")
                        .font(.caption2)
                        .foregroundColor(Theme.muted)
                    RoundedRectangle(cornerRadius: 2).fill(Theme.red).frame(width: 10, height: 10)
                    Text("L")
                        .font(.caption2)
                        .foregroundColor(Theme.muted)
                }
            }
        }
    }
}

private struct BreakAdvantageRow: View {
    let label: String
    let wins: Int
    let total: Int

    private var pct: Double { total > 0 ? Double(wins) / Double(total) : 0 }
    private var pctText: String { total > 0 ? "\(Int(round(pct * 100)))%" : "—" }
    private var fractionText: String { total > 0 ? "\(wins)/\(total)" : "no data" }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(Theme.text2)
                Spacer()
                Text(fractionText)
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(Theme.muted)
                Text(pctText)
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundColor(total > 0 ? (pct >= 0.5 ? Theme.green : Theme.red) : Theme.muted)
                    .frame(width: 36, alignment: .trailing)
            }
            if total > 0 {
                PercentageBar(value: Int(round(pct * 100)), color: pct >= 0.5 ? Theme.green : Theme.red, height: 6)
            }
        }
    }
}

private struct OpponentRow: View {
    let profile: OpponentProfile
    let isSelected: Bool
    let lastSeenText: String
    let actionSelect: () -> Void
    let actionFavorite: () -> Void
    let actionEdit: () -> Void
    let actionDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isSelected ? Theme.purple.opacity(0.18) : Theme.panel2)
                    .frame(width: 36, height: 36)
                Text(initials)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.text)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(profile.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.text)
                        .lineLimit(1)
                    if profile.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(Theme.amber)
                    }
                }
                Text("Last seen \(lastSeenText)")
                    .font(.caption2)
                    .foregroundColor(Theme.text2)
            }

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                buttonIcon("star", filled: profile.isFavorite, tint: Theme.amber, action: actionFavorite)
                buttonIcon("pencil", filled: false, tint: Theme.purple, action: actionEdit)
                buttonIcon("trash", filled: false, tint: Theme.red, action: actionDelete)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isSelected ? Theme.panel2 : Theme.panel)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Theme.purple.opacity(0.45) : Theme.border, lineWidth: 0.5))
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture(perform: actionSelect)
    }

    private var initials: String {
        let parts = profile.displayName.split(whereSeparator: { $0 == " " || $0 == "-" }).prefix(2)
        let letters = parts.compactMap { $0.first }.map { String($0) }
        return letters.isEmpty ? "?" : letters.joined().uppercased()
    }

    private func buttonIcon(_ systemName: String, filled: Bool, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName + (filled && systemName == "star" ? ".fill" : ""))
                .font(.caption.weight(.semibold))
                .foregroundColor(tint)
                .frame(width: 28, height: 28)
                .background(Theme.panel2)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(tint.opacity(0.35), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}

private enum OpponentEditorMode: Hashable, Identifiable {
    case add
    case edit(OpponentProfile)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let profile): return "edit-\(profile.id.uuidString)"
        }
    }

    var title: String {
        switch self {
        case .add: return "Add opponent"
        case .edit: return "Edit opponent"
        }
    }

    var initialName: String {
        switch self {
        case .add: return ""
        case .edit(let profile): return profile.displayName
        }
    }
}

private struct OpponentEditorSheet: View {
    let mode: OpponentEditorMode
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String

    init(mode: OpponentEditorMode, onSave: @escaping (String) -> Void) {
        self.mode = mode
        self.onSave = onSave
        _name = State(initialValue: mode.initialName)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    SectionCard(title: mode.title) {
                        VStack(alignment: .leading, spacing: 10) {
                            TextField("Opponent name", text: $name)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .background(Theme.bg.opacity(0.45))
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))

                            Text("Use the name you recognize most often.")
                                .font(.caption2)
                                .foregroundColor(Theme.text2)
                        }
                    }
                }
                .padding(.horizontal, Layout.pagePadding)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
            .background(Theme.bg)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
