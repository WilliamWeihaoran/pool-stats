import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var opponentStore: OpponentStore
    @State private var filter: GameFilter = .all
    @State private var opponentFilter: String = "All opponents"
    @State private var searchText: String = ""
    @State private var selection = Set<Int64>()
    @State private var isSelecting: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var selectedSession: Session?
    @State private var activePickerID: String? = nil

    var body: some View {
        ZStack {
            VStack(spacing: 6) {
                headerRow
                filterBar
                actionRow
                if store.sessions.isEmpty {
                        SectionCard(title: "No sessions yet") {
                            Text("You can restore the built-in sample data to explore the app.")
                                .font(.caption)
                                .foregroundColor(Theme.muted)
                            Button("Restore sample data") {
                                Task { await store.restoreSampleData() }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else {
                        List {
                            ForEach(filteredSessions) { session in
                                Button {
                                    if isSelecting {
                                        toggleSelection(session.id)
                                    } else {
                                        selectedSession = session
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        if isSelecting {
                                            Image(systemName: selection.contains(session.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(selection.contains(session.id) ? Theme.purple : Theme.muted)
                                        }
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 8) {
                                                Text(session.displayLabel)
                                                    .font(.headline)
                                                    .foregroundColor(Theme.text)
                                                    .lineLimit(1)
                                                if session.isPractice {
                                                    badge(text: "Practice", color: Theme.muted)
                                                } else if session.isDraw {
                                                    badge(text: "Draw", color: Theme.muted)
                                                }
                                                if !session.opponent.isEmpty {
                                                    badge(text: session.opponent, color: Theme.blue)
                                                }
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        Spacer(minLength: 8)
                                        HStack(spacing: 4) {
                                            Text(AppFormatters.sessionDate(session.ts))
                                            Text("·")
                                            Text(session.durationSeconds.map { $0 > 0 ? AppFormatters.duration(seconds: $0) : "—" } ?? "—")
                                        }
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(Theme.text2.opacity(0.88))
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.leading, 10)
                                    .padding(.trailing, 12)
                                    .overlay(alignment: .leading) {
                                        Rectangle()
                                            .fill(session.resultAccentColor.opacity(0.55))
                                            .frame(width: 3)
                                            .cornerRadius(2)
                                    }
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(Theme.panel2)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
                pickerOverlay
            }
            .background(Theme.bg)
            .searchable(text: $searchText)
            .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: Binding(
            get: { selectedSession != nil },
            set: { if !$0 { selectedSession = nil } }
        )) {
            if let session = selectedSession {
                SummaryView(session: session)
            }
        }
        .alert("Delete selected sessions?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task { await store.deleteSessions(ids: Array(selection)) }
                selection.removeAll()
                isSelecting = false
            }
            Button("Cancel", role: .cancel) { }
        }
        .task {
            opponentStore.sync(with: store.sessions)
        }
    }

    @ViewBuilder
    private var pickerOverlay: some View {
        if activePickerID == "history.game" {
            OverlayPickerPanel(title: "Game",
                               items: [GameFilter.all, .practice, .eightBall, .nineBall],
                               selection: $filter,
                               label: { $0.label },
                               onDismiss: { activePickerID = nil })
        } else if activePickerID == "history.opponent" {
            OverlayPickerPanel(title: "Opponent",
                               items: opponentOptions,
                               selection: $opponentFilter,
                               label: { $0 },
                               onDismiss: { activePickerID = nil })
        }
    }

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 10) {
            Text("History")
                .font(.title.bold())
                .foregroundColor(Theme.text)
            Spacer(minLength: 8)
            syncStatusBadge
        }
        .padding(.horizontal, 14)
        .padding(.top, 4)
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

    private var syncStatusBadge: some View {
        HStack(spacing: 6) {
            Group {
                switch store.syncStatus {
                case .loading, .syncing:
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Theme.purple)
                case .synced:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.green)
                case .localOnly:
                    Image(systemName: "tray.and.arrow.down.fill")
                        .foregroundColor(Theme.amber)
                case .error:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Theme.red)
                }
            }
            .font(.caption2)
            Text(syncTitle)
                .font(.caption2.weight(.medium))
                .foregroundColor(Theme.text2)
                .lineLimit(1)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(Theme.panel2)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            InlinePickerCard(id: "history.game",
                             title: "Game",
                             items: [GameFilter.all, .practice, .eightBall, .nineBall],
                             selection: $filter,
                             activeID: $activePickerID) { $0.label }

            if !opponentOptions.isEmpty {
                InlinePickerCard(id: "history.opponent",
                                 title: "Opponent",
                                 items: opponentOptions,
                                 selection: $opponentFilter,
                                 activeID: $activePickerID) { $0 }
            }
        }
        .padding(.horizontal, 14)
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button {
                Task { await store.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.text2)
                    .frame(width: 30, height: 30)
                    .background(Theme.panel)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            if isSelecting {
                Button {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(selection.isEmpty ? Theme.muted : Theme.red)
                        .frame(width: 30, height: 30)
                        .background(Theme.panel)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .disabled(selection.isEmpty)
            }

            Button(isSelecting ? "Done" : "Select") {
                if isSelecting {
                    selection.removeAll()
                }
                isSelecting.toggle()
            }
            .buttonStyle(.bordered)
            .tint(Theme.purple)
        }
        .padding(.horizontal, 14)
    }

    private var filteredSessions: [Session] {
        var rows = store.sessions.sorted { $0.ts > $1.ts }
        if opponentFilter != "All opponents" {
            rows = rows.filter { opponentStore.matches($0.opponent, selected: opponentFilter) }
        }
        switch filter {
        case .practice:
            rows = rows.filter { $0.type == "practice" }
        case .eightBall:
            rows = rows.filter { $0.game == "8ball" && $0.type != "practice" }
        case .nineBall:
            rows = rows.filter { $0.game == "9ball" && $0.type != "practice" }
        case .all:
            break
        }
        if !searchText.isEmpty {
            rows = rows.filter { $0.label.lowercased().contains(searchText.lowercased()) }
        }
        return rows
    }

    private var opponentOptions: [String] {
        opponentStore.availableNames(from: store.sessions)
    }

    private var syncTitle: String {
        switch store.syncStatus {
        case .loading: return "Syncing session data"
        case .syncing: return "Syncing session data"
        case .synced: return "iCloud synced"
        case .localOnly: return "Local cache active"
        case .error: return "Sync issue"
        }
    }

    private var syncSubtitle: String {
        switch store.syncStatus {
        case .loading:
            return "Loading local cache and checking iCloud."
        case .syncing:
            return "Saving to iCloud and local cache."
        case .synced:
            return "Latest sessions are stored locally and in CloudKit."
        case .localOnly(let message):
            return message
        case .error(let message):
            return message
        }
    }

    private func toggleSelection(_ id: Int64) {
        if selection.contains(id) {
            selection.remove(id)
        } else {
            selection.insert(id)
        }
    }
}
