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
