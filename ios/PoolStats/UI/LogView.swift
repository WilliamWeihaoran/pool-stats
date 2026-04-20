import SwiftUI

struct LogView: View {
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var logStore: SessionLogStore
    @State private var label: String = ""
    @State private var showSaveToast: Bool = false
    @State private var showEndConfirm: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if logStore.currentSession == nil {
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
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showEndConfirm) {
            EndSessionConfirmationSheet(
                onSave: {
                    Task { await logStore.endSession(savingTo: store) }
                },
                onDiscard: {
                    logStore.discardSession()
                }
            )
            .presentationDetents([.height(220)])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: Binding(
            get: { logStore.lastEndedSession },
            set: { _ in logStore.lastEndedSession = nil }
        )) { session in
            NavigationStack {
                SummaryView(session: session)
            }
        }
    }
}

private struct EndSessionConfirmationSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("End session?")
                    .font(.headline)
                    .foregroundColor(Theme.text)
                Text("Save the session to history, discard it, or keep logging.")
                    .font(.caption)
                    .foregroundColor(Theme.muted)
            }

            HStack(spacing: 10) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .tint(Theme.text2)
                .frame(maxWidth: .infinity)

                Button("Discard") {
                    dismiss()
                    onDiscard()
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.red)
                .frame(maxWidth: .infinity)
            }

            Button("Save") {
                dismiss()
                onSave()
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.teal)
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(Theme.bg)
    }
}
