import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var opponentStore: OpponentStore
    var showsHeader: Bool = true
    @State private var opponentFilter: String = "All opponents"
    @State private var searchText: String = ""
    @State private var selection = Set<Int64>()
    @State private var isSelecting: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var pendingDeleteIDs: [Int64] = []
    @State private var selectedSession: Session?
    @State private var activePickerID: String? = nil

    var body: some View {
        ZStack {
            VStack(spacing: 6) {
                if showsHeader {
                    headerRow
                }
                filterBar
                actionRow
                statusSummaryCard
                if store.sessions.isEmpty {
                    emptyLibraryState
                } else if filteredSessions.isEmpty {
                    emptyFilteredState
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
                                            if session.isDrillPractice {
                                                badge(text: "Drill", color: Theme.purple)
                                                badge(text: session.drillDifficultyLabel, color: Theme.amber)
                                            } else if session.isPractice {
                                                badge(text: "Practice", color: Theme.muted)
                                            } else {
                                                badge(text: session.gameLabel, color: Theme.teal)
                                            }
                                            if !session.opponent.isEmpty {
                                                badge(text: session.opponent, color: Theme.blue)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                        Text(sessionSummaryText(session))
                                            .font(.caption2)
                                            .foregroundColor(Theme.text2)
                                            .lineLimit(2)
                                    }

                                    Spacer(minLength: 8)

                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(AppFormatters.sessionDate(session.ts))
                                        Text(session.durationSeconds.map { $0 > 0 ? AppFormatters.duration(seconds: $0) : "—" } ?? "—")
                                    }
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(Theme.text2.opacity(0.88))
                                }
                                .padding(.vertical, 4)
                                .padding(.leading, 13)
                                .padding(.trailing, 12)
                                .overlay(alignment: .leading) {
                                    Rectangle()
                                        .fill(session.resultAccentColor)
                                        .frame(width: 5)
                                        .cornerRadius(2)
                                }
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Theme.panel2)
                            .swipeActions(edge: .trailing, allowsFullSwipe: !isSelecting) {
                                if !isSelecting {
                                    Button(role: .destructive) {
                                        requestDelete(ids: [session.id])
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
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
        .alert(deleteAlertTitle, isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                let ids = pendingDeleteIDs
                pendingDeleteIDs = []
                selection.removeAll()
                isSelecting = false
                Task { await store.deleteSessions(ids: ids) }
            }
            Button("Cancel", role: .cancel) {
                pendingDeleteIDs = []
            }
        } message: {
            Text(deleteAlertMessage)
        }
        .task {
            opponentStore.sync(with: store.sessions)
        }
    }

    @ViewBuilder
    private var pickerOverlay: some View {
        if activePickerID == "history.opponent" {
            OverlayPickerPanel(title: "Opponent",
                               items: opponentOptions,
                               selection: $opponentFilter,
                               label: { $0 },
                               onDismiss: { activePickerID = nil })
        }
    }

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("History")
                    .font(.title.bold())
                    .foregroundColor(Theme.text)
                Text("Browse past matches and practice sessions, then jump back into any summary.")
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
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

    private func drillSummaryText(_ session: Session) -> String {
        let rate = session.drillSuccessRate.map { "\($0)% success" } ?? "No attempts"
        return "\(session.drillAttempts) attempts · \(rate) · \(session.drillDifficultyLabel)"
    }

    private func sessionSummaryText(_ session: Session) -> String {
        if session.isDrillPractice {
            return drillSummaryText(session)
        }
        if session.isPractice {
            return "\(session.gameLabel) practice · \(session.racks.count) racks"
        }
        let scoreText = session.isDraw ? "Draw \(session.wins):\(session.losses)" : "Score \(session.wins):\(session.losses)"
        return "\(session.gameLabel) match · \(scoreText)"
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
                actionChip(label: "Refresh", systemName: "arrow.clockwise", color: Theme.text2)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            if isSelecting {
                Button {
                    requestDelete(ids: Array(selection))
                } label: {
                    actionChip(
                        label: selection.isEmpty ? "Delete" : "Delete \(selection.count)",
                        systemName: "trash",
                        color: selection.isEmpty ? Theme.muted : Theme.red
                    )
                }
                .buttonStyle(.plain)
                .disabled(selection.isEmpty)
            }

            Button {
                if isSelecting {
                    selection.removeAll()
                }
                isSelecting.toggle()
            }
            label: {
                actionChip(
                    label: isSelecting ? "Done" : "Select",
                    systemName: isSelecting ? "checkmark.circle" : "checklist",
                    color: Theme.purple
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
    }

    private var statusSummaryCard: some View {
        SectionCard(title: isSelecting ? "Selection" : "Status") {
            VStack(alignment: .leading, spacing: 10) {
                Text(isSelecting ? selectionSummaryText : historySummaryText)
                    .font(.caption)
                    .foregroundColor(Theme.text2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    summaryPill(text: "\(filteredSessions.count) shown", color: Theme.teal)
                    if opponentFilter != "All opponents" {
                        summaryPill(text: opponentFilter, color: Theme.blue)
                    }
                    if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        summaryPill(text: "Search active", color: Theme.amber)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
    }

    private var filteredSessions: [Session] {
        var rows = store.sessions.sorted(by: Session.newestFirst)
        if opponentFilter != "All opponents" {
            rows = rows.filter { opponentStore.matches($0.opponent, selected: opponentFilter) }
        }
        if !searchText.isEmpty {
            rows = rows.filter { $0.label.lowercased().contains(searchText.lowercased()) }
        }
        return rows
    }

    private var deleteAlertTitle: String {
        pendingDeleteIDs.count == 1 ? "Delete session?" : "Delete selected sessions?"
    }

    private var deleteAlertMessage: String {
        if pendingDeleteIDs.count == 1 {
            return "This session will be removed from History."
        }
        return "\(pendingDeleteIDs.count) sessions will be removed from History."
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

    private func requestDelete(ids: [Int64]) {
        guard ids.isEmpty == false else { return }
        pendingDeleteIDs = ids
        showDeleteConfirm = true
    }

    private var historySummaryText: String {
        if filteredSessions.isEmpty {
            return "No sessions match the current filter, so this is a good place to clear the search or switch opponents."
        }
        return "\(filteredSessions.count) sessions currently visible. \(syncSubtitle)"
    }

    private var selectionSummaryText: String {
        if selection.isEmpty {
            return "Tap sessions to select them for deletion."
        }
        return "\(selection.count) session\(selection.count == 1 ? "" : "s") selected. Deleting removes them from History."
    }

    private var emptyLibraryState: some View {
        SectionCard(title: "No sessions yet") {
            VStack(alignment: .leading, spacing: 10) {
                Text("You can restore the built-in sample data to explore the app.")
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                Button("Restore sample data") {
                    Task { await store.restoreSampleData() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, 14)
    }

    private var emptyFilteredState: some View {
        SectionCard(title: "Nothing matches") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Try clearing the search or switching back to all opponents.")
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                Button("Clear filters") {
                    opponentFilter = "All opponents"
                    searchText = ""
                    activePickerID = nil
                }
                .buttonStyle(.bordered)
                .tint(Theme.purple)
            }
        }
        .padding(.horizontal, 14)
    }

    private func actionChip(label: String, systemName: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemName)
                .font(.caption.weight(.semibold))
            Text(label)
                .font(.caption.weight(.semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 11)
        .frame(height: 32)
        .background(Theme.panel)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Theme.border, lineWidth: 0.5)
        )
    }

    private func summaryPill(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
