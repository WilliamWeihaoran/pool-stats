import SwiftUI

struct GoalTemplate: Identifiable {
    let id = UUID()
    let title: String
    let metric: GoalMetric
    let window: GoalWindow
    let target: Double
}

struct GoalDraft: Identifiable {
    let id = UUID()
    var originalID: UUID? = nil
    var title: String = ""
    var metric: GoalMetric = .conversionRate
    var target: Double = 55
    var valueStyle: GoalValueStyle = .cumulative
    var averageBasis: GoalAverageBasis = .racks
    var sessionScope: GoalSessionScope = .all
    var notes: String = ""
    var starterGenerated: Bool = false
    var windowMode: GoalWindowMode = .rolling
    var rollingAmount: Int = 30
    var rollingUnit: GoalWindowUnit = .sessions
    var dueDate: Date = defaultDueDate()

    init() {
        dueDate = Self.defaultDueDate()
    }

    init(goal: Goal) {
        originalID = goal.id
        title = goal.title
        metric = goal.metric
        target = goal.target
        valueStyle = goal.valueStyle
        averageBasis = goal.averageBasis
        sessionScope = goal.sessionScope
        notes = goal.notes
        starterGenerated = goal.starterGenerated
        switch goal.window {
        case .rolling(let rolling):
            windowMode = .rolling
            rollingAmount = max(rolling.amount, 1)
            rollingUnit = rolling.unit
            dueDate = Self.defaultDueDate()
        case .dueDate(let date):
            windowMode = .dueDate
            dueDate = date
        }
    }

    init(resetFrom goal: Goal) {
        title = goal.title
        metric = goal.metric
        target = goal.metric.suggestedResetTarget(from: goal.target)
        valueStyle = goal.valueStyle
        averageBasis = goal.averageBasis
        sessionScope = goal.sessionScope
        notes = goal.notes
        starterGenerated = false
        switch goal.window {
        case .rolling(let rolling):
            windowMode = .rolling
            rollingAmount = max(rolling.amount, 1)
            rollingUnit = rolling.unit
            dueDate = Self.defaultDueDate()
        case .dueDate(let date):
            windowMode = .dueDate
            rollingAmount = 30
            rollingUnit = .sessions
            dueDate = date
        }
    }

    init(template: GoalTemplate) {
        title = template.title
        metric = template.metric
        target = template.target
        valueStyle = template.metric.supportsValueStyle ? template.metric.defaultValueStyle : .cumulative
        averageBasis = template.metric.defaultAverageBasis
        sessionScope = .all
        notes = ""
        starterGenerated = false
        switch template.window {
        case .rolling(let rolling):
            windowMode = .rolling
            rollingAmount = max(rolling.amount, 1)
            rollingUnit = rolling.unit
            dueDate = Self.defaultDueDate()
        case .dueDate(let date):
            windowMode = .dueDate
            dueDate = date
        }
    }

    var window: GoalWindow {
        switch windowMode {
        case .rolling:
            return .rolling(.init(amount: max(rollingAmount, 1), unit: rollingUnit))
        case .dueDate:
            return .dueDate(dueDate)
        }
    }

    mutating func normalizeAggregation() {
        guard metric.supportsValueStyle else {
            valueStyle = .cumulative
            averageBasis = metric.defaultAverageBasis
            return
        }
        if valueStyle != .average, metric.defaultValueStyle == .average {
            valueStyle = .average
        }
        averageBasis = valueStyle == .average && averageBasis == .sessions ? .sessions : metric.defaultAverageBasis
    }

    func makeGoal() -> Goal {
        Goal(title: title.trimmingCharacters(in: .whitespacesAndNewlines),
             metric: metric,
             target: target,
             window: window,
             valueStyle: valueStyle,
             averageBasis: averageBasis,
             sessionScope: sessionScope,
             notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
             starterGenerated: starterGenerated)
    }

    static func defaultDueDate() -> Date {
        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        return cal.date(from: DateComponents(year: year, month: 12, day: 31)) ?? Date()
    }
}

enum GoalWindowMode: String, CaseIterable, Identifiable {
    case rolling
    case dueDate

    var id: String { rawValue }

    var label: String {
        switch self {
        case .rolling: return NSLocalizedString("Rolling", comment: "")
        case .dueDate: return NSLocalizedString("Due date", comment: "")
        }
    }
}

struct GoalEditorCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(Theme.text2)
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.panel)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
    }
}

struct MetricGroupSection: View {
    let title: String
    let subtitle: String
    let accent: Color
    let metrics: [GoalMetric]
    @Binding var selectedMetric: GoalMetric

    var columns: [GridItem] {
        let count = metrics.count == 1 ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Capsule()
                        .fill(accent)
                        .frame(width: 18, height: 3)
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.text)
                }
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(Theme.muted)
            }

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(metrics) { metric in
                    MetricChoiceButton(metric: metric,
                                       accent: accent,
                                       isSelected: selectedMetric == metric) {
                        selectedMetric = metric
                    }
                }
            }
        }
    }
}

struct MetricChoiceButton: View {
    let metric: GoalMetric
    let accent: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 8) {
                Text(metric.label)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(isSelected ? Theme.text : Theme.text2)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
                    .foregroundColor(isSelected ? accent : Theme.border)
            }
            .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? accent.opacity(0.16) : Color.clear)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? accent : Theme.border, lineWidth: isSelected ? 1 : 0.7))
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct GhostChipButton: View {
    let title: String
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(accent)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(accent.opacity(0.08))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.45), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 10))
    }
}
