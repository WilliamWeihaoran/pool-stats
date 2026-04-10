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
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.label.isEmpty ? "—" : session.label)
                                        .font(.headline)
                                    Text(metaLine(session))
                                        .font(.caption)
                                        .foregroundColor(Theme.muted)
                                }
                            }
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
                ToolbarItem(placement: .bottomBar) {
                    Button("Delete") { showDeleteConfirm = true }
                        .disabled(selection.isEmpty)
                }
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

    private func metaLine(_ session: Session) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "MMM d, yy"
        let date = df.string(from: session.ts)
        let badge = session.isPractice ? "Practice" : (session.game == "8ball" ? "8-ball" : "9-ball")
        let racks = session.racks.count
        let winPercent: String
        if session.isPractice {
            winPercent = "—"
        } else {
            let won = session.racks.filter { $0.result == "won" }.count
            winPercent = racks == 0 ? "—" : "\(Int(round(Double(won) / Double(racks) * 100)))%"
        }
        let bnr = session.racks.filter { $0.breakAndRun }.count
        let errors = session.racks.reduce(0) { $0 + $1.fouls + $1.badSafety + $1.badPosition + $1.planChange + $1.missEasy + $1.missMed + $1.missHard }
        let errPerRack = racks == 0 ? "—" : String(format: "%.1f", Double(errors) / Double(racks))
        return "\(date) · \(badge) · \(racks) racks · \(winPercent) · B&R \(bnr) · \(errPerRack) err/rack"
    }
}
