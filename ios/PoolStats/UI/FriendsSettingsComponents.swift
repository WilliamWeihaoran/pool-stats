import SwiftUI

struct SocialPanel<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(title))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.text)
                Text(LocalizedStringKey(subtitle))
                    .font(.caption2)
                    .foregroundColor(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            content()
        }
        .padding(12)
        .background(Theme.panel2.opacity(0.42))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.border.opacity(0.65), lineWidth: 0.5)
        )
    }
}

struct SocialEmptyState: View {
    let message: String

    var body: some View {
        Text(LocalizedStringKey(message))
            .font(.caption2)
            .foregroundColor(Theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Theme.panel2.opacity(0.7))
            .cornerRadius(10)
    }
}

struct SocialActionChip: View {
    let label: String
    let systemName: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemName)
                .font(.caption2.weight(.bold))
            Text(LocalizedStringKey(label))
                .font(.caption2.weight(.semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 0.6))
    }
}

enum MatchSharePresentation {
    static func statusText(for share: IncomingMatchShare) -> String {
        if share.isAccepted { return NSLocalizedString("Accepted", comment: "") }
        if share.isDeclined { return NSLocalizedString("Declined", comment: "") }
        return NSLocalizedString("Pending", comment: "")
    }

    static func accent(for share: IncomingMatchShare) -> Color {
        if share.isAccepted { return Theme.green }
        if share.isDeclined { return Theme.muted }
        return Theme.amber
    }

    static func statusText(for share: OutgoingMatchShare) -> String {
        if share.isAccepted { return NSLocalizedString("Accepted", comment: "") }
        if share.isDeclined { return NSLocalizedString("Declined", comment: "") }
        if share.isFailed { return NSLocalizedString("Failed", comment: "") }
        return NSLocalizedString("Pending", comment: "")
    }

    static func accent(for share: OutgoingMatchShare) -> Color {
        if share.isAccepted { return Theme.green }
        if share.isDeclined { return Theme.red }
        if share.isFailed { return Theme.red }
        return Theme.amber
    }

    static func icon(for share: OutgoingMatchShare) -> String {
        if share.isAccepted { return "checkmark" }
        if share.isDeclined { return "xmark" }
        if share.isFailed { return "exclamationmark" }
        return "paperplane.fill"
    }
}
