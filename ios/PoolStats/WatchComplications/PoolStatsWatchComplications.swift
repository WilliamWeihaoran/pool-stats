import SwiftUI
import WidgetKit

private struct ComplicationEntry: TimelineEntry {
    let date: Date
    let snapshot: WatchComplicationSnapshot
}

private struct SharedSnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> ComplicationEntry {
        ComplicationEntry(date: .now, snapshot: .inactive)
    }

    func getSnapshot(in context: Context, completion: @escaping (ComplicationEntry) -> Void) {
        completion(ComplicationEntry(date: .now, snapshot: WatchComplicationStateStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ComplicationEntry>) -> Void) {
        let snapshot = WatchComplicationStateStore.load()
        let now = Date()
        var dates = [now]
        if snapshot.recentlyEndedAt != nil {
            let midnight = Calendar.current.startOfDay(for: now).addingTimeInterval(24 * 60 * 60)
            dates.append(midnight)
        }
        let entries = dates.map { ComplicationEntry(date: $0, snapshot: snapshot) }
        let policy: TimelineReloadPolicy = snapshot.recentlyEndedAt == nil ? .never : .after(dates.last ?? now)
        completion(Timeline(entries: entries, policy: policy))
    }
}

@main
struct PoolStatsWatchComplicationsBundle: WidgetBundle {
    var body: some Widget {
        QuickLogComplication()
        LiveScoreComplication()
        SessionActiveComplication()
    }
}

struct QuickLogComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PoolStatsQuickLogComplication", provider: SharedSnapshotProvider()) { entry in
            QuickLogComplicationView(entry: entry)
                .widgetURL(WatchComplicationStateStore.url(for: .quickLog))
        }
        .configurationDisplayName("Quick Log")
        .description("Launch PoolStats on the watch and start logging fast.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

struct LiveScoreComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PoolStatsLiveScoreComplication", provider: SharedSnapshotProvider()) { entry in
            LiveScoreComplicationView(entry: entry)
                .widgetURL(WatchComplicationStateStore.url(for: entry.snapshot.hasActiveSession ? .activeSession : .quickLog))
        }
        .configurationDisplayName("Live Score")
        .description("Show a live match score or a quick-log fallback when idle.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct SessionActiveComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PoolStatsSessionActiveComplication", provider: SharedSnapshotProvider()) { entry in
            SessionActiveComplicationView(entry: entry)
                .widgetURL(WatchComplicationStateStore.url(for: entry.snapshot.hasActiveSession ? .activeSession : .quickLog))
        }
        .configurationDisplayName("Session Active")
        .description("Resume the active watch session or jump into quick log.")
        .supportedFamilies([.accessoryRectangular])
    }
}

private struct QuickLogComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ComplicationEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                Circle()
                    .fill(Color(red: 0.14, green: 0.17, blue: 0.24))
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(red: 0.37, green: 0.92, blue: 0.83))
            }
            .widgetAccentable()
        default:
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(red: 0.14, green: 0.17, blue: 0.24))
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(red: 0.37, green: 0.92, blue: 0.83))
                }
                .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Quick Log")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Open logger")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 2)
        }
    }
}

private struct LiveScoreComplicationView: View {
    let entry: ComplicationEntry

    var body: some View {
        let snapshot = entry.snapshot
        if snapshot.hasActiveSession {
            if snapshot.type == "practice" {
                HStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(red: 0.37, green: 0.92, blue: 0.83))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(gameLabel(snapshot.game))
                            .font(.system(size: 13, weight: .semibold))
                        Text("Practice")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(red: 0.68, green: 0.54, blue: 0.98))
                    }
                    Spacer(minLength: 0)
                }
            } else {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Live Score")
                            .font(.system(size: 12, weight: .semibold))
                        Text(opponentLabel(snapshot))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    HStack(spacing: 3) {
                        Text("\(snapshot.wins)")
                            .foregroundStyle(Color(red: 0.37, green: 0.92, blue: 0.83))
                        Text(":")
                            .foregroundStyle(.secondary)
                        Text("\(snapshot.losses)")
                            .foregroundStyle(Color(red: 0.97, green: 0.44, blue: 0.44))
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                }
            }
        } else if shouldShowRecentScore(snapshot) {
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    if let endedAt = snapshot.recentlyEndedAt {
                        Text(endedAt, style: .relative)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                    }
                    Text(opponentLabel(snapshot))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                HStack(spacing: 3) {
                    Text("\(snapshot.wins)")
                        .foregroundStyle(Color(red: 0.37, green: 0.92, blue: 0.83))
                    Text(":")
                        .foregroundStyle(.secondary)
                    Text("\(snapshot.losses)")
                        .foregroundStyle(Color(red: 0.97, green: 0.44, blue: 0.44))
                }
                .font(.system(size: 18, weight: .bold, design: .rounded))
            }
        } else {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(red: 0.37, green: 0.92, blue: 0.83))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Live Score")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Start a session")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

private struct SessionActiveComplicationView: View {
    let entry: ComplicationEntry

    var body: some View {
        let snapshot = entry.snapshot
        if snapshot.hasActiveSession {
            HStack(spacing: 8) {
                Image(systemName: "circle.badge.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(red: 0.37, green: 0.92, blue: 0.83))

                VStack(alignment: .leading, spacing: 1) {
                    Text("Session Active")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text("\(sessionActiveLabel(snapshot)) • \(snapshot.wins):\(snapshot.losses)")
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
        } else {
            HStack(spacing: 8) {
                Image(systemName: "pause.circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Session Active")
                        .font(.system(size: 12, weight: .semibold))
                    Text("No Session")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

private func gameLabel(_ raw: String?) -> String {
    switch raw {
    case "9ball": return "9-ball"
    case "8ball": return "8-ball"
    default: return "Pool"
    }
}

private func opponentLabel(_ snapshot: WatchComplicationSnapshot) -> String {
    let cleaned = snapshot.opponent?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if cleaned.isEmpty || cleaned == "Other" {
        return gameLabel(snapshot.game)
    }
    return cleaned
}

private func sessionActiveLabel(_ snapshot: WatchComplicationSnapshot) -> String {
    if snapshot.type == "match" {
        return opponentLabel(snapshot)
    }
    return gameLabel(snapshot.game)
}

private func shouldShowRecentScore(_ snapshot: WatchComplicationSnapshot, now: Date = .now) -> Bool {
    WatchSyncReconciler.shouldShowRecentScore(
        hasActiveSession: snapshot.hasActiveSession,
        updatedAt: snapshot.updatedAt,
        recentlyEndedAt: snapshot.recentlyEndedAt,
        now: now
    )
}
