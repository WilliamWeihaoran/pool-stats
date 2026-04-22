import SwiftUI

struct GoalsView: View {
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var goalsStore: GoalsStore
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @State private var editorDraft: GoalDraft?
    @State private var showArchived = false
    @State private var actionGoal: Goal?
    @State private var celebrationGoal: Goal?
    @State private var resetPromptGoal: Goal?

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 14) {
                    header
                    overviewSection
                    activeGoalsSection
                    if archivedGoals.isEmpty == false {
                        archivedSection
                    }
                    addSection
                }
                .padding(.horizontal, Layout.pagePadding)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
            .background(Theme.bg)

            if let goal = actionGoal {
                GoalActionOverlay(goal: goal,
                                  onEdit: {
                                      editorDraft = GoalDraft(goal: goal)
                                      actionGoal = nil
                                  },
                                  onComplete: {
                                      completeGoal(goal)
                                  },
                                  onArchive: {
                                      goalsStore.toggleArchive(goal)
                                      actionGoal = nil
                                  },
                                  onDelete: {
                                      goalsStore.delete(goal)
                                      actionGoal = nil
                                  },
                                  onReset: {
                                      resetPromptGoal = goal
                                      actionGoal = nil
                                  },
                                  onDismiss: {
                                      actionGoal = nil
                                  })
            }

            if let goal = celebrationGoal {
                GoalCelebrationOverlay(goal: goal)
            }

            if let goal = resetPromptGoal {
                GoalResetPrompt(goal: goal,
                                onReset: {
                                    editorDraft = GoalDraft(resetFrom: goal)
                                    resetPromptGoal = nil
                                },
                                onLater: {
                                    resetPromptGoal = nil
                                })
            }
        }
        .sheet(item: $editorDraft) { draft in
            GoalEditorSheet(draft: draft) { updated in
                if let originalID = updated.originalID,
                   let goal = goalsStore.goals.first(where: { $0.id == originalID }) {
                    var next = goal
                    next.title = updated.title
                    next.metric = updated.metric
                    next.window = updated.window
                    next.target = updated.target
                    next.notes = updated.notes
                    goalsStore.update(next)
                } else {
                    goalsStore.add(updated.makeGoal())
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Goals")
                .font(.title.bold())
                .foregroundColor(Theme.text)
            Spacer(minLength: 0)
        }
        .padding(.top, 4)
        .padding(.horizontal, 2)
    }

    private var overviewSection: some View {
        let active = activeGoals
        let complete = active.filter { isComplete($0) }.count
        return VStack(alignment: .leading, spacing: 10) {
            Text("Overview")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.text2)
                .padding(.horizontal, 2)
            LazyVGrid(columns: Layout.fourColumn(), spacing: Layout.gridSpacing) {
                StatCard(label: "Active", value: "\(active.count)")
                StatCard(label: "Complete", value: "\(complete)")
                StatCard(label: "Archived", value: "\(archivedGoals.count)")
                StatCard(label: "Sessions", value: "\(store.sessions.count)")
            }
        }
    }

    private var activeGoalsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Active goals")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.text2)
                .padding(.horizontal, 2)
            VStack(spacing: 10) {
                if activeGoals.isEmpty {
                    emptyState
                } else {
                    ForEach(activeGoals) { goal in
                        GoalCard(goal: goal,
                                 currentValue: currentValue(for: goal),
                                 isComplete: isComplete(goal),
                                 onEdit: { editorDraft = GoalDraft(goal: goal) },
                                 onMore: { actionGoal = goal })
                    }
                }
            }
        }
    }

    private var archivedSection: some View {
        SectionCard(title: "Archived") {
            VStack(spacing: 10) {
                Toggle(isOn: $showArchived) {
                    Text("Show archived goals")
                        .font(.caption)
                        .foregroundColor(Theme.text2)
                }
                .tint(Theme.purple)

                if showArchived {
                    VStack(spacing: 10) {
                        ForEach(archivedGoals) { goal in
                            GoalCard(goal: goal,
                                     currentValue: currentValue(for: goal),
                                     isComplete: isComplete(goal),
                                     archived: true,
                                     onEdit: { editorDraft = GoalDraft(goal: goal) },
                                     onMore: { actionGoal = goal })
                        }
                    }
                }
            }
        }
    }

    private var addSection: some View {
        SectionCard(title: "Start here") {
            VStack(alignment: .leading, spacing: 10) {
                VStack(spacing: 10) {
                    ForEach(Self.templates) { template in
                        Button {
                            editorDraft = GoalDraft(template: template)
                        } label: {
                            HStack(spacing: 10) {
                                Text(template.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(Theme.text)
                                Spacer(minLength: 0)
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(Theme.purple)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.panel2)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button {
                    editorDraft = GoalDraft()
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Create custom goal")
                        Spacer()
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Theme.panel2)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
                }
                .buttonStyle(.plain)

                Button("Restore starter goals") {
                    goalsStore.resetToSamples()
                }
                .font(.caption.weight(.medium))
                .buttonStyle(.bordered)
                .tint(Theme.purple)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No active goals yet.")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.panel2)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
    }

    private var activeGoals: [Goal] {
        goalsStore.goals.filter { !$0.isArchived }
    }

    private var archivedGoals: [Goal] {
        goalsStore.goals.filter { $0.isArchived }
    }

    private func currentValue(for goal: Goal) -> Double {
        let sessions = goal.window.apply(to: store.sessions, createdAt: goal.createdAt)
        return goal.metric.value(from: sessions)
    }

    private func isComplete(_ goal: Goal) -> Bool {
        let current = currentValue(for: goal)
        return goal.metric.isLowerBetter ? current <= goal.target : current >= goal.target
    }

    private func completeGoal(_ goal: Goal) {
        goalsStore.complete(goal)
        actionGoal = nil
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
            celebrationGoal = goal
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            withAnimation(.easeOut(duration: 0.2)) {
                celebrationGoal = nil
                resetPromptGoal = goal
            }
        }
    }

    private static let templates: [GoalTemplate] = [
        GoalTemplate(title: "Open conversion to 55%", metric: .conversionRate, window: .rolling(.init(amount: 30, unit: .sessions)), target: 55),
        GoalTemplate(title: "Match win rate above 60%", metric: .matchWinRate, window: .rolling(.init(amount: 10, unit: .sessions)), target: 60),
        GoalTemplate(title: "Miss errors under 8", metric: .missErrors, window: .rolling(.init(amount: 30, unit: .sessions)), target: 8),
        GoalTemplate(title: "Positional errors under 6", metric: .positionalErrors, window: .rolling(.init(amount: 30, unit: .sessions)), target: 6),
        GoalTemplate(title: "Average rating 7.0+", metric: .averagePerformance, window: .rolling(.init(amount: 10, unit: .sessions)), target: 7),
        GoalTemplate(title: "Record 4+ runouts", metric: .runouts, window: .rolling(.init(amount: 30, unit: .sessions)), target: 4),
        GoalTemplate(title: "Break-and-runs: 2+", metric: .breakAndRuns, window: .rolling(.init(amount: 30, unit: .sessions)), target: 2)
    ]
}

private struct GoalCard: View {
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
        case .missErrors, .positionalErrors, .safetyErrors, .foulErrors:
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
                    Text("\(goal.metric.label) · \(goal.window.label)")
                        .font(.caption2)
                        .foregroundColor(Theme.muted)
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
                Text(goal.metric.format(currentValue))
                    .font(.headline)
                    .foregroundColor(archived ? Theme.text2 : barColor)
                Spacer()
                Text("Target \(goal.metric.format(goal.target))")
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
}

private struct GoalActionOverlay: View {
    let goal: Goal
    let onEdit: () -> Void
    let onComplete: () -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void
    let onReset: () -> Void
    let onDismiss: () -> Void

    private var archiveTitle: String {
        if goal.completedAt != nil { return "Reset goal" }
        return goal.isArchived ? "Unarchive" : "Archive"
    }

    private var archiveAccent: Color {
        goal.completedAt != nil ? Theme.purple : Theme.amber
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack {
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Theme.text)
                        Text("Choose an action")
                            .font(.caption)
                            .foregroundColor(Theme.muted)
                    }

                    VStack(spacing: 8) {
                        GoalActionButton(title: "Edit", systemImage: "pencil", accent: Theme.teal, action: onEdit)
                        if goal.completedAt == nil {
                            GoalActionButton(title: "Complete", systemImage: "checkmark.seal.fill", accent: Theme.green, action: onComplete)
                        }
                        GoalActionButton(title: archiveTitle,
                                         systemImage: goal.completedAt != nil ? "arrow.counterclockwise" : (goal.isArchived ? "tray.and.arrow.down.fill" : "archivebox.fill"),
                                         accent: archiveAccent,
                                         action: goal.completedAt != nil ? onReset : onArchive)
                        GoalActionButton(title: "Delete", systemImage: "trash.fill", accent: Theme.red, destructive: true, action: onDelete)
                    }

                    Button("Cancel", action: onDismiss)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.text2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.panel2.opacity(0.75))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.5))
                }
                .padding(16)
                .background(Theme.panel)
                .cornerRadius(22)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.border, lineWidth: 0.5))
                .padding(.horizontal, Layout.pagePadding)
                .padding(.bottom, 12)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: goal.id)
    }
}

private struct GoalActionButton: View {
    let title: String
    let systemImage: String
    let accent: Color
    var destructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .frame(width: 18)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 0)
            }
            .foregroundColor(destructive ? Theme.red : accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background((destructive ? Theme.red : accent).opacity(0.10))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke((destructive ? Theme.red : accent).opacity(0.45), lineWidth: 0.8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct GoalCelebrationOverlay: View {
    let goal: Goal
    @State private var pulse = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                ZStack {
                    ForEach(0..<10, id: \.self) { idx in
                        Image(systemName: idx % 2 == 0 ? "sparkles" : "star.fill")
                            .font(.caption.weight(.bold))
                            .foregroundColor([Theme.green, Theme.purple, Theme.amber, Theme.teal, Theme.red][idx % 5])
                            .offset(
                                x: CGFloat(cos(Double(idx) * .pi / 5.0)) * (pulse ? 68 : 22),
                                y: CGFloat(sin(Double(idx) * .pi / 5.0)) * (pulse ? 68 : 22)
                            )
                            .opacity(pulse ? 0.95 : 0.35)
                            .scaleEffect(pulse ? 1.1 : 0.7)
                    }

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(Theme.green)
                        .scaleEffect(pulse ? 1.0 : 0.75)
                }
                .frame(width: 140, height: 140)

                Text("Goal complete")
                    .font(.title3.bold())
                    .foregroundColor(Theme.text)

                Text(goal.title)
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 240)
            }
            .padding(22)
            .background(Theme.panel)
            .cornerRadius(24)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.border, lineWidth: 0.5))
            .padding(.horizontal, Layout.pagePadding * 2)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.18).repeatCount(4, autoreverses: true)) {
                pulse = true
            }
        }
        .transition(.opacity.combined(with: .scale))
    }
}

private struct GoalResetPrompt: View {
    let goal: Goal
    let onReset: () -> Void
    let onLater: () -> Void

    private var suggestedTargetText: String {
        goal.metric.format(goal.metric.suggestedResetTarget(from: goal.target))
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack {
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Reset this goal?")
                        .font(.title3.bold())
                        .foregroundColor(Theme.text)
                    Text("We can start a new version with a nudged target: \(suggestedTargetText).")
                        .font(.caption)
                        .foregroundColor(Theme.muted)

                    Button {
                        onReset()
                    } label: {
                        HStack {
                            Text("Reset goal")
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.bg)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(Theme.purple)
                        .cornerRadius(14)
                    }
                    .buttonStyle(.plain)

                    Button {
                        onLater()
                    } label: {
                        Text("Not now")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Theme.text2)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Theme.panel2.opacity(0.75))
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(Theme.panel)
                .cornerRadius(22)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.border, lineWidth: 0.5))
                .padding(.horizontal, Layout.pagePadding)
                .padding(.bottom, 12)
            }
        }
        .transition(.opacity.combined(with: .scale))
    }
}

private struct GoalTemplate: Identifiable {
    let id = UUID()
    let title: String
    let metric: GoalMetric
    let window: GoalWindow
    let target: Double
}

private struct GoalDraft: Identifiable {
    let id = UUID()
    var originalID: UUID? = nil
    var title: String = ""
    var metric: GoalMetric = .conversionRate
    var target: Double = 55
    var notes: String = ""
    var windowMode: GoalWindowMode = .rolling
    var rollingAmount: Int = 30
    var rollingUnit: GoalWindowUnit = .sessions
    var dueDateText: String = ""

    init() {
        dueDateText = AppFormatters.dueDateInput(Self.defaultDueDate())
    }

    init(goal: Goal) {
        originalID = goal.id
        title = goal.title
        metric = goal.metric
        target = goal.target
        notes = goal.notes
        switch goal.window {
        case .rolling(let rolling):
            windowMode = .rolling
            rollingAmount = max(rolling.amount, 1)
            rollingUnit = rolling.unit
            dueDateText = AppFormatters.dueDateInput(Self.defaultDueDate())
        case .dueDate(let date):
            windowMode = .dueDate
            dueDateText = AppFormatters.dueDateInput(date)
        }
    }

    init(resetFrom goal: Goal) {
        title = goal.title
        metric = goal.metric
        target = goal.metric.suggestedResetTarget(from: goal.target)
        notes = goal.notes
        switch goal.window {
        case .rolling(let rolling):
            windowMode = .rolling
            rollingAmount = max(rolling.amount, 1)
            rollingUnit = rolling.unit
            dueDateText = AppFormatters.dueDateInput(Self.defaultDueDate())
        case .dueDate(let date):
            windowMode = .dueDate
            rollingAmount = 30
            rollingUnit = .sessions
            dueDateText = AppFormatters.dueDateInput(date)
        }
    }

    init(template: GoalTemplate) {
        title = template.title
        metric = template.metric
        target = template.target
        notes = ""
        switch template.window {
        case .rolling(let rolling):
            windowMode = .rolling
            rollingAmount = max(rolling.amount, 1)
            rollingUnit = rolling.unit
            dueDateText = AppFormatters.dueDateInput(Self.defaultDueDate())
        case .dueDate(let date):
            windowMode = .dueDate
            dueDateText = AppFormatters.dueDateInput(date)
        }
    }

    var window: GoalWindow {
        switch windowMode {
        case .rolling:
            return .rolling(.init(amount: max(rollingAmount, 1), unit: rollingUnit))
        case .dueDate:
            return .dueDate(AppFormatters.parseDueDateInput(dueDateText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? Self.defaultDueDate())
        }
    }

    func makeGoal() -> Goal {
        Goal(title: title.trimmingCharacters(in: .whitespacesAndNewlines),
             metric: metric,
             target: target,
             window: window,
             notes: notes.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    static func defaultDueDate() -> Date {
        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        return cal.date(from: DateComponents(year: year, month: 12, day: 31)) ?? Date()
    }
}

private struct GoalEditorSheet: View {
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
                windowSection
                targetSection
                notesSection
                actionButtons
            }
            .padding(Layout.pagePadding)
            .padding(.top, 8)
            .padding(.bottom, 18)
        }
        .background(Theme.bg.ignoresSafeArea())
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

            Slider(value: Binding(
                get: { Double(draft.rollingAmount) },
                set: { draft.rollingAmount = max(1, Int(round($0))) }
            ), in: 1...365, step: 1)
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
                Text("YYYY-MM-DD")
                    .font(.caption2)
                    .foregroundColor(Theme.muted)
            }

            TextField("2026-12-31", text: $draft.dueDateText)
                .font(.subheadline.monospacedDigit())
                .foregroundColor(Theme.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(Theme.panel2)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))

            HStack(spacing: 8) {
                GhostChipButton(title: "30d", accent: Theme.purple) {
                    draft.dueDateText = AppFormatters.dueDateInput(Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date())
                }
                GhostChipButton(title: "90d", accent: Theme.purple) {
                    draft.dueDateText = AppFormatters.dueDateInput(Calendar.current.date(byAdding: .day, value: 90, to: Date()) ?? Date())
                }
                GhostChipButton(title: "End year", accent: Theme.purple) {
                    draft.dueDateText = AppFormatters.dueDateInput(GoalDraft.defaultDueDate())
                }
            }

            Text("Use a due date like Dec 31, 2026.")
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
}

private enum GoalWindowMode: String, CaseIterable, Identifiable {
    case rolling
    case dueDate

    var id: String { rawValue }

    var label: String {
        switch self {
        case .rolling: return "Rolling"
        case .dueDate: return "Due date"
        }
    }
}

private struct GoalEditorCard<Content: View>: View {
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

private struct MetricGroupSection: View {
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

            LazyVGrid(columns: columns, spacing: 8) {
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

private struct MetricChoiceButton: View {
    let metric: GoalMetric
    let accent: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(metric.label)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(isSelected ? Theme.text : Theme.text2)
                            .lineLimit(2)
                        Spacer(minLength: 0)
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.caption)
                            .foregroundColor(isSelected ? accent : Theme.border)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            .background(isSelected ? accent.opacity(0.16) : Color.clear)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? accent : Theme.border, lineWidth: isSelected ? 1 : 0.7))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct GhostChipButton: View {
    let title: String
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(accent)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(accent.opacity(0.08))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.45), lineWidth: 0.8))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
