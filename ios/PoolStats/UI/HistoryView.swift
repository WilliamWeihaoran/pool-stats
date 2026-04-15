import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: DataStore
    @State private var filter: GameFilter = .all
    @State private var searchText: String = ""
    @State private var selection = Set<Int64>()
    @State private var showDeleteConfirm: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                filterBar
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
                    List(selection: $selection) {
                        ForEach(filteredSessions) { session in
                            NavigationLink(destination: SummaryView(session: session)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(session.label.isEmpty ? "—" : session.label)
                                        .font(.headline)
                                    HStack(spacing: 8) {
                                        Text(dateText(session.ts))
                                        Text("•")
                                        Text(durationText(session))
                                    }
                                    .font(.caption)
                                    .foregroundColor(Theme.muted)
                                }
                            }
                            .listRowBackground(sessionTint(session).opacity(0.12))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.bg)
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Refresh") { Task { await store.refresh() } }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .safeAreaInset(edge: .bottom) {
                deleteBar
            }
            .searchable(text: $searchText)
            .alert("Delete selected sessions?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    Task { await store.deleteSessions(ids: Array(selection)) }
                    selection.removeAll()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach([GameFilter.all, .practice, .eightBall, .nineBall]) { f in
                    PillButton(label: f.label, isOn: filter == f) {
                        filter = f
                    }
                }
            }
            .padding(.horizontal, 14)
        }
    }

    private var filteredSessions: [Session] {
        var rows = store.sessions.sorted { $0.ts > $1.ts }
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

    private func dateText(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "MMM d, yyyy"
        return df.string(from: date)
    }

    private func durationText(_ session: Session) -> String {
        guard let seconds = session.durationSeconds, seconds > 0 else { return "—" }
        let hrs = seconds / 3600
        let mins = (seconds % 3600) / 60
        if hrs > 0 {
            return "\(hrs)h \(mins)m"
        }
        return "\(mins)m"
    }

    private func sessionTint(_ session: Session) -> Color {
        guard !session.isPractice else { return Color.clear }
        let wins = session.racks.filter { $0.result == "won" }.count
        let losses = session.racks.filter { $0.result == "lost" }.count
        if wins > losses { return Theme.green }
        if losses > wins { return Theme.red }
        return Color.clear
    }

    private var deleteBar: some View {
        HStack {
            Button {
                showDeleteConfirm = true
            } label: {
                Text("Delete Selected")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.red)
            .disabled(selection.isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Theme.bg.opacity(0.98))
    }
}
