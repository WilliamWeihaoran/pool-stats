import SwiftUI

struct GoalEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @State private var draft: GoalDraft
    let onSave: (GoalDraft) -> Void

    init(draft: GoalDraft, onSave: @escaping (GoalDraft) -> Void) {
        _draft = State(initialValue: draft)
        self.onSave = onSave
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                editorHeader
                titleSection
                metricSection
                sessionTypeSection
                measureSection
                windowSection
                targetSection
                previewSection
                notesSection
                actionButtons
            }
            .padding(Layout.pagePadding)
            .padding(.top, 8)
            .padding(.bottom, 18)
        }
        .background(Theme.bg.ignoresSafeArea())
        .onChange(of: draft.metric) { _ in
            draft.normalizeAggregation()
        }
    }

    private var editorHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(draft.originalID == nil ? "New Goal" : "Edit Goal")
                .font(.title3.bold())
                .foregroundColor(Theme.text)
            Text("Pick a metric, choose a window, and set the target.")
                .font(.caption)
                .foregroundColor(Theme.muted)
        }
    }

    private var titleSection: some View {
        GoalEditorCard(title: "Goal name") {
            TextField("e.g. Match win rate above 70%", text: $draft.title)
                .font(.subheadline)
                .foregroundColor(Theme.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(Theme.panel2)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
        }
    }

    private var metricSection: some View {
        GoalEditorCard(title: "Metric") {
            VStack(alignment: .leading, spacing: 12) {
                MetricGroupSection(title: "Grow", subtitle: "Goals you want to lift", accent: Theme.teal, metrics: growthMetrics, selectedMetric: $draft.metric)
                MetricGroupSection(title: "Trim", subtitle: "Goals you want to bring down", accent: Theme.amber, metrics: trimMetrics, selectedMetric: $draft.metric)
            }
        }
    }

    private var measureSection: some View {
        Group {
            if draft.metric.supportsValueStyle {
                GoalEditorCard(title: "Measure") {
                    VStack(alignment: .leading, spacing: 10) {
                        SegmentedRow(items: GoalValueStyle.allCases, selection: $draft.valueStyle) { $0.label }

                        if draft.valueStyle == .average {
                            SegmentedRow(items: GoalAverageBasis.allCases, selection: $draft.averageBasis) { $0.label }
                        }
                    }
                }
            }
        }
    }

    private var sessionTypeSection: some View {
        GoalEditorCard(title: "Session type") {
            SegmentedRow(items: GoalSessionScope.allCases, selection: $draft.sessionScope) { $0.label }
        }
    }

    private var windowSection: some View {
        GoalEditorCard(title: "Time frame") {
            VStack(alignment: .leading, spacing: 10) {
                SegmentedRow(items: GoalWindowMode.allCases, selection: $draft.windowMode) { $0.label }

                if draft.windowMode == .rolling {
                    rollingWindowEditor
                } else {
                    dueDateEditor
                }
            }
        }
    }

    private var rollingWindowEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("Count")
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                Spacer(minLength: 0)
                Text("\(draft.rollingAmount)")
                    .font(.headline)
                    .foregroundColor(Theme.text)
                    .frame(minWidth: 44, alignment: .trailing)
            }

            let upperBound: Double = {
                switch draft.rollingUnit {
                case .racks:
                    return 100
                case .sessions:
                    return 100
                case .days:
                    return 365
                case .weeks:
                    return 52
                }
            }()

            Slider(value: Binding(
                get: { Double(draft.rollingAmount) },
                set: { draft.rollingAmount = max(1, Int(round($0))) }
            ), in: 1...upperBound, step: 1)
            .tint(Theme.purple)

            HStack(spacing: 10) {
                Text("Quick set")
                    .font(.caption2)
                    .foregroundColor(Theme.muted)
                Spacer(minLength: 0)
                ForEach([10, 30, 100], id: \.self) { value in
                    Button {
                        draft.rollingAmount = value
                    } label: {
                        Text("\(value)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(draft.rollingAmount == value ? Theme.text : Theme.text2)
                            .frame(minWidth: 34)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(draft.rollingAmount == value ? Theme.panel2 : Color.clear)
                            .cornerRadius(9)
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(draft.rollingAmount == value ? Theme.purple : Theme.border, lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                }
            }

            LazyVGrid(columns: Layout.twoColumn(), spacing: 8) {
                ForEach(GoalWindowUnit.allCases) { unit in
                    Button {
                        draft.rollingUnit = unit
                    } label: {
                        HStack {
                            Text(unit.label)
                                .font(.caption.weight(.semibold))
                            Spacer(minLength: 0)
                            if draft.rollingUnit == unit {
                                Image(systemName: "checkmark")
                                    .font(.caption2.weight(.bold))
                            }
                        }
                        .foregroundColor(draft.rollingUnit == unit ? Theme.text : Theme.text2)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(draft.rollingUnit == unit ? Theme.panel2 : Color.clear)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(draft.rollingUnit == unit ? Theme.purple : Theme.border, lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var dueDateEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Due date")
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                Spacer(minLength: 0)
                Text(AppFormatters.sessionDate(draft.dueDate))
                    .font(.caption2.weight(.medium))
                    .foregroundColor(Theme.text2)
            }

            DatePicker("", selection: $draft.dueDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(Theme.purple)
                .frame(maxWidth: .infinity, minHeight: 330, alignment: .top)
                .padding(10)
                .background(Theme.panel2)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))

            HStack(spacing: 8) {
                GhostChipButton(title: "30d", accent: Theme.purple) {
                    draft.dueDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
                }
                GhostChipButton(title: "90d", accent: Theme.purple) {
                    draft.dueDate = Calendar.current.date(byAdding: .day, value: 90, to: Date()) ?? Date()
                }
                GhostChipButton(title: "End year", accent: Theme.purple) {
                    draft.dueDate = GoalDraft.defaultDueDate()
                }
            }

            Text("Pick an exact due date from the calendar.")
                .font(.caption2)
                .foregroundColor(Theme.muted)
        }
    }

    private var targetSection: some View {
        GoalEditorCard(title: "Target") {
            HStack(spacing: 10) {
                Text("Goal value")
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                Spacer(minLength: 0)
                TextField("55", value: $draft.target, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(Theme.text)
                    .frame(width: 100)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(Theme.panel2)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
        }
    }

    private var previewSection: some View {
        GoalEditorCard(title: "Plain English") {
            Text(previewText)
                .font(.caption)
                .foregroundColor(Theme.text2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var notesSection: some View {
        GoalEditorCard(title: "Note") {
            TextField("Optional note", text: $draft.notes, axis: .vertical)
                .lineLimit(3, reservesSpace: true)
                .font(.subheadline)
                .foregroundColor(Theme.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(Theme.panel2)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.text2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.panel)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
            }
            .buttonStyle(.plain)

            Button {
                onSave(draft)
                dismiss()
            } label: {
                Text("Save goal")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Theme.border : Theme.purple)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.top, 4)
    }

    private var growthMetrics: [GoalMetric] {
        GoalMetric.allCases.filter { $0.direction == .improve }
    }

    private var trimMetrics: [GoalMetric] {
        GoalMetric.allCases.filter { $0.direction == .reduce }
    }

    private var previewText: String {
        let draftGoal = Goal(title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? NSLocalizedString("This goal", comment: "") : draft.title,
                             metric: draft.metric,
                             target: draft.target,
                             window: draft.window,
                             valueStyle: draft.valueStyle,
                             averageBasis: draft.averageBasis,
                             sessionScope: draft.sessionScope,
                             notes: draft.notes)
        return draftGoal.plainEnglishSummary
    }
}
