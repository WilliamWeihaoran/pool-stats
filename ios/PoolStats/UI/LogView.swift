import SwiftUI
import UIKit

struct LogLiteModeKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

struct LogView: View {
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var logStore: SessionLogStore
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var label: String = ""
    @State private var showSaveToast: Bool = false
    @State private var showEndConfirm: Bool = false
    @State private var forceLiteScoreboard: Bool = false
    @State private var isLandscape: Bool = false
    @State private var suppressAutoLite: Bool = false

    private var showLite: Bool {
        guard let session = logStore.currentSession, session.isDrillPractice == false else { return false }
        if forceLiteScoreboard { return true }
        if suppressAutoLite { return false }
        return isLandscape || verticalSizeClass == .compact
    }

    var body: some View {
        Group {
            if showLite {
                LogActiveView(
                    showSaveToast: $showSaveToast,
                    showEndConfirm: $showEndConfirm,
                    showLiteScoreboard: true,
                    onScoreCardTap: { exitLite() }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        if logStore.currentSession == nil {
                            LogStartView(label: $label)
                        } else if logStore.currentSession?.isDrillPractice == true {
                            DrillLogActiveView(showEndConfirm: $showEndConfirm)
                        } else {
                            LogActiveView(
                                showSaveToast: $showSaveToast,
                                showEndConfirm: $showEndConfirm,
                                showLiteScoreboard: false,
                                onScoreCardTap: { enterLite() }
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 0)
                    .padding(.bottom, 12)
                }
                .background(Theme.bg)
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { isLandscape = geo.size.width > geo.size.height }
                    .onChange(of: geo.size) { newSize in
                        isLandscape = newSize.width > newSize.height
                    }
            }
        )
        .onChange(of: isLandscape) { newValue in
            if !newValue {
                forceLiteScoreboard = false
                suppressAutoLite = false
            }
        }
        .preference(key: LogLiteModeKey.self, value: showLite)
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear {
            if forceLiteScoreboard {
                forceLiteScoreboard = false
                requestOrientation(.portrait)
            }
        }
        .sheet(isPresented: $showEndConfirm) {
            EndSessionConfirmationSheet(
                onSave: {
                    _ = logStore.saveRack()
                    Task { await logStore.endSession(savingTo: store) }
                },
                onDiscard: {
                    logStore.discardSession()
                }
            )
            .presentationDetents([.height(220)])
            .presentationDragIndicator(.hidden)
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

    private func enterLite() {
        forceLiteScoreboard = true
        requestOrientation(.landscape)
    }

    private func exitLite() {
        forceLiteScoreboard = false
        suppressAutoLite = true
    }

    private func requestOrientation(_ mask: UIInterfaceOrientationMask) {
        AppDelegate.orientationLock = .allButUpsideDown
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        scene.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask)) { _ in }
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
                Text("Save this session to history, discard it, or keep logging.")
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.bg)
    }
}
