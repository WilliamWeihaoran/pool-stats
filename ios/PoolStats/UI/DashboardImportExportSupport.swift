import SwiftUI
import UniformTypeIdentifiers

struct DashboardImportExportState {
    var isShowingExporter = false
    var isShowingImporter = false
    var exportDocument: JSONDocument?
    var pendingImportData: Data?
    var pendingImportPreview: JSONImportPreview?
    var isShowingImportConfirmation = false
    var importErrorMessage = ""
    var isShowingImportError = false
    var exportErrorMessage = ""
    var isShowingExportError = false

    mutating func stageImport(data: Data, preview: JSONImportPreview) {
        pendingImportData = data
        pendingImportPreview = preview
        isShowingImportConfirmation = true
    }

    mutating func clearPendingImport() {
        pendingImportData = nil
        pendingImportPreview = nil
        isShowingImportConfirmation = false
    }
}

struct DashboardImportExportSection: View {
    let onExport: () -> Void
    let onImport: () -> Void

    var body: some View {
        SectionCard(title: NSLocalizedString("Data backup", comment: "")) {
            VStack(alignment: .leading, spacing: 12) {
                Text(NSLocalizedString("Export all Pool Stats data to a JSON backup, or import a previous backup to replace the data included in that file.", comment: ""))
                    .font(.caption)
                    .foregroundColor(Theme.muted)

                HStack(spacing: 8) {
                    Button(action: onExport) {
                        Text(NSLocalizedString("↓ Export JSON", comment: ""))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Theme.text)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Theme.panel2)
                            .cornerRadius(10)
                    }

                    Button(action: onImport) {
                        Text(NSLocalizedString("↑ Import JSON", comment: ""))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Theme.text)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Theme.panel2)
                            .cornerRadius(10)
                    }
                }
            }
        }
    }
}

private struct DashboardImportExportModifier: ViewModifier {
    @Binding var state: DashboardImportExportState
    @ObservedObject var store: DataStore
    @ObservedObject var goalsStore: GoalsStore
    @ObservedObject var opponentStore: OpponentStore
    @ObservedObject var profileStore: PlayerProfileStore
    @ObservedObject var socialProfileStore: SocialProfileStore
    @ObservedObject var logStore: SessionLogStore

    func body(content: Content) -> some View {
        content
            .fileExporter(
                isPresented: $state.isShowingExporter,
                document: state.exportDocument,
                contentType: .json,
                defaultFilename: exportFilename
            ) { result in
                state.exportDocument = nil
                if case let .failure(error) = result {
                    state.exportErrorMessage = error.localizedDescription
                    state.isShowingExportError = true
                }
            }
            .fileImporter(
                isPresented: $state.isShowingImporter,
                allowedContentTypes: [.json]
            ) { result in
                handleImportSelection(result)
            }
            .alert(NSLocalizedString("Replace sessions?", comment: ""), isPresented: $state.isShowingImportConfirmation) {
                Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) {
                    state.clearPendingImport()
                }
                Button(NSLocalizedString("Import", comment: ""), role: .destructive) {
                    guard let data = state.pendingImportData else {
                        state.clearPendingImport()
                        return
                    }
                    state.clearPendingImport()
                    Task {
                        await importBackup(data)
                    }
                }
            } message: {
                Text(importConfirmationMessage)
            }
            .alert(NSLocalizedString("Import failed", comment: ""), isPresented: $state.isShowingImportError) {
                Button(NSLocalizedString("OK", comment: ""), role: .cancel) { }
            } message: {
                Text(state.importErrorMessage)
            }
            .alert(NSLocalizedString("Export failed", comment: ""), isPresented: $state.isShowingExportError) {
                Button(NSLocalizedString("OK", comment: ""), role: .cancel) { }
            } message: {
                Text(state.exportErrorMessage)
            }
    }

    private var exportFilename: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return "pool-stats-export-\(formatter.string(from: Date()))"
    }

    private var importConfirmationMessage: String {
        let preview = state.pendingImportPreview ?? JSONImportPreview(sessionCount: 0, includesSupplementalData: false)
        let count = preview.sessionCount
        let singular = NSLocalizedString("session", comment: "")
        let plural = NSLocalizedString("sessions", comment: "")
        let sessionCopy = count == 1 ? singular : plural
        if preview.includesSupplementalData {
            let format = NSLocalizedString("Importing will replace your sessions plus any goals, opponents, profile, social, and active-session data included in this backup. This backup contains %d %@.", comment: "")
            return String(format: format, count, sessionCopy)
        }
        let format = NSLocalizedString("Importing will replace the current session history in Pool Stats with %d %@ from this backup and sync the change to iCloud.", comment: "")
        return String(format: format, count, sessionCopy)
    }

    private func handleImportSelection(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let values = try url.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = values.fileSize, fileSize > JSONTransfer.maximumImportByteCount {
                throw JSONTransfer.TransferError.fileTooLarge
            }
            let data = try Data(contentsOf: url)
            let preview = try JSONTransfer.previewImport(data)
            state.stageImport(data: data, preview: preview)
        } catch {
            state.importErrorMessage = error.localizedDescription
            state.isShowingImportError = true
        }
    }

    private func importBackup(_ data: Data) async {
        do {
            let backup = try JSONTransfer.importBackup(data)
            await store.importSessionsFromBackup(backup.sessions)

            if let goals = backup.goals {
                goalsStore.replaceAll(goals)
            }
            if let opponents = backup.opponents {
                opponentStore.replaceAll(opponents)
            }
            if let playerProfile = backup.playerProfile {
                profileStore.replaceProfile(playerProfile)
            }
            if let social = backup.social {
                socialProfileStore.replaceLocalBackup(social)
            }
            if backup.includesSupplementalData {
                logStore.restoreActiveSnapshot(backup.activeSession)
            }
        } catch {
            state.importErrorMessage = error.localizedDescription
            state.isShowingImportError = true
        }
    }
}

extension View {
    func dashboardImportExportPresentation(
        state: Binding<DashboardImportExportState>,
        store: DataStore,
        goalsStore: GoalsStore,
        opponentStore: OpponentStore,
        profileStore: PlayerProfileStore,
        socialProfileStore: SocialProfileStore,
        logStore: SessionLogStore
    ) -> some View {
        modifier(
            DashboardImportExportModifier(
                state: state,
                store: store,
                goalsStore: goalsStore,
                opponentStore: opponentStore,
                profileStore: profileStore,
                socialProfileStore: socialProfileStore,
                logStore: logStore
            )
        )
    }
}
