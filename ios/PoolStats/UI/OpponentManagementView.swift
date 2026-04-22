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
