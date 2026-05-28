import SwiftUI
import UniformTypeIdentifiers

struct DashboardImportExportState {
    var isShowingExporter = false
    var isShowingImporter = false
    var exportDocument: JSONDocument?
    var pendingImportData: Data?
    var pendingImportCount: Int?
    var isShowingImportConfirmation = false
    var importErrorMessage = ""
    var isShowingImportError = false
    var exportErrorMessage = ""
    var isShowingExportError = false

    mutating func stageImport(data: Data, count: Int) {
        pendingImportData = data
        pendingImportCount = count
        isShowingImportConfirmation = true
    }

    mutating func clearPendingImport() {
        pendingImportData = nil
        pendingImportCount = nil
        isShowingImportConfirmation = false
    }
}

struct DashboardImportExportSection: View {
    let onExport: () -> Void
    let onImport: () -> Void

    var body: some View {
        SectionCard(title: NSLocalizedString("Data backup", comment: "")) {
            VStack(alignment: .leading, spacing: 12) {
                Text(NSLocalizedString("Export your sessions to a JSON backup, or import a previous Pool Stats export to replace your current session history.", comment: ""))
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
                        await store.importJSON(data)
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
        let count = state.pendingImportCount ?? 0
        let format = NSLocalizedString("Importing will replace the current data in Pool Stats with %d %@ from this backup and sync the change to iCloud.", comment: "")
        let singular = NSLocalizedString("session", comment: "")
        let plural = NSLocalizedString("sessions", comment: "")
        let sessionCopy = count == 1 ? singular : plural
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
            let count = try JSONTransfer.previewImportCount(data)
            state.stageImport(data: data, count: count)
        } catch {
            state.importErrorMessage = error.localizedDescription
            state.isShowingImportError = true
        }
    }
}

extension View {
    func dashboardImportExportPresentation(
        state: Binding<DashboardImportExportState>,
        store: DataStore
    ) -> some View {
        modifier(DashboardImportExportModifier(state: state, store: store))
    }
}
