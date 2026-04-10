import SwiftUI

struct LogView: View {
    @EnvironmentObject private var store: DataStore
    @State private var label: String = ""
    @State private var showSaveToast: Bool = false
    @State private var showEndConfirm: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 10) {
                    if store.currentSession == nil {
                        LogStartView(label: $label)
                    } else {
                        LogActiveView(showSaveToast: $showSaveToast, showEndConfirm: $showEndConfirm)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 2)
                .padding(.bottom, 12)
            }
            .background(Theme.bg)
            .alert("End session?", isPresented: $showEndConfirm) {
                Button("End Session", role: .destructive) {
                    Task { await store.endSession() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will finish the current session and save it to history.")
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: Binding(
            get: { store.lastEndedSession },
            set: { _ in store.lastEndedSession = nil }
        )) { session in
            NavigationView {
                SummaryView(session: session)
            }
        }
    }
}

struct LogSectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundColor(Theme.muted)
            content
        }
        .padding(8)
        .background(Theme.panel)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
    }
}
