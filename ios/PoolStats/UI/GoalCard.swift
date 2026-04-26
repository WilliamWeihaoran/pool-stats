import SwiftUI

struct GoalCard: View {
    let goal: Goal
    let currentValue: Double
    let isComplete: Bool
    var archived: Bool = false
    let onEdit: () -> Void
    let onMore: () -> Void

    private var completion: Double {
        guard goal.target > 0 else { return 0 }
        let raw = goal.metric.isLowerBetter ? goal.target / max(currentValue, 0.0001) : currentValue / goal.target
        return min(max(raw, 0), 1)
    }

    private var barColor: Color {
        if goal.completedAt != nil { return Theme.green }
        if isComplete { return Theme.green }
        switch goal.metric {
        case .missErrors, .positionalErrors, .safetyErrors, .patternErrors, .foulErrors:
            return Theme.amber
        case .averagePerformance:
            return Theme.purple
        default:
            return Theme.teal
        }
    }

    private var statusColor: Color {
        if goal.completedAt != nil { return Theme.green }
        if archived { return Theme.text2 }
        return barColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(goal.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(archived ? Theme.text2 : Theme.text)
                        if let badge = statusBadgeText {
                            Text(badge)
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(statusColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(statusColor.opacity(0.12))
                                .cornerRadius(999)
                        }
                    }
                    HStack(spacing: 8) {
                        Text(goal.window.label)
                            .font(.caption2)
                            .foregroundColor(Theme.muted)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Text(goal.sessionScope.shortLabel.lowercased())
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(scopeColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(scopeColor.opacity(0.14))
                            .cornerRadius(999)
                    }
                }
                Spacer(minLength: 0)
                Button(action: onMore) {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(Theme.text2)
                }
                .buttonStyle(.plain)
            }

            HStack {
                Text(goal.metric.format(currentValue, style: goal.valueStyle, basis: goal.averageBasis))
                    .font(.headline)
                    .foregroundColor(archived ? Theme.text2 : barColor)
                Spacer()
                Text("Target \(goal.metric.format(goal.target, style: goal.valueStyle, basis: goal.averageBasis))")
                    .font(.caption.weight(.medium))
                    .foregroundColor(Theme.text2)
            }

            PercentageBar(value: Int(round(completion * 100)), color: barColor, height: 7)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.panel2.opacity(archived ? 0.7 : 1))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.5))
    }

    private var statusBadgeText: String? {
        if goal.completedAt != nil { return "Completed" }
        if archived { return "Archived" }
        return nil
    }

    private var scopeColor: Color {
        switch goal.sessionScope {
        case .all: return Theme.text2
        case .match: return Theme.teal
        case .practice: return Theme.amber
        }
    }
}
