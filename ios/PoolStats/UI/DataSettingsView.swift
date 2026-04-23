import SwiftUI

struct DataSettingsView: View {
    @EnvironmentObject private var store: DataStore

    var body: some View {
        SectionCard(title: "Data") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Sync status")
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                    Spacer()
                    syncBadge
                }

                infoRow(label: "Sync health", value: syncHealthText)
                infoRow(label: "Last cloud sync", value: lastCloudSyncText)
                if let reason = store.lastSyncFailureReason, !reason.isEmpty {
                    Text(reason)
                        .font(.caption)
                        .foregroundColor(Theme.amber)
                }

                Button("Restore sample data") {
                    Task { await store.restoreSampleData() }
                }
                .buttonStyle(.bordered)
                .tint(Theme.purple)

                Text("Sessions are saved locally first and then synced to iCloud.")
                    .font(.caption)
                    .foregroundColor(Theme.text2)
            }
        }
    }

    private var syncBadge: some View {
        HStack(spacing: 6) {
            Group {
                switch store.syncStatus {
                case .loading, .syncing:
                    ProgressView().progressViewStyle(.circular).tint(Theme.purple)
                case .synced:
                    Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.green)
                case .localOnly:
                    Image(systemName: "tray.and.arrow.down.fill").foregroundColor(Theme.amber)
                case .error:
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(Theme.red)
                }
            }
            .font(.caption2)
            Text(syncStatusText)
                .font(.caption2.weight(.medium))
                .foregroundColor(Theme.text2)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(Theme.panel2)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
    }

    private var syncStatusText: String {
        switch store.syncStatus {
        case .loading: return "Loading"
        case .syncing: return "Syncing"
        case .synced: return "iCloud synced"
        case .localOnly: return "Local cache active"
        case .error: return "Sync issue"
        }
    }

    private var syncHealthText: String {
        if let reason = store.lastSyncFailureReason, !reason.isEmpty {
            return "Needs attention"
        }
        if store.lastSyncSuccessAt != nil {
            return "Healthy"
        }
        if store.lastSyncAttemptAt != nil {
            return "Checking"
        }
        return "Unknown"
    }

    private var lastCloudSyncText: String {
        if let last = store.lastSyncSuccessAt {
            return AppFormatters.shortDateTime(last)
        }
        if let attempted = store.lastSyncAttemptAt {
            return "Last attempt \(AppFormatters.shortDateTime(attempted))"
        }
        return "Never"
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(Theme.muted)
            Spacer()
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundColor(Theme.text)
        }
    }
}
