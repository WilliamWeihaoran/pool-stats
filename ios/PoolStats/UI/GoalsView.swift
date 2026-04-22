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
                }
                .padding(.horizontal, Layout.pagePadding)
                .padding(.top, 0)
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
                    next.valueStyle = updated.valueStyle
                    next.averageBasis = updated.averageBasis
                    next.sessionScope = updated.sessionScope
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
            Button {
                editorDraft = GoalDraft()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.text)
                    .frame(width: 34, height: 34)
                    .background(Theme.panel2)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Theme.border, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
        .padding(.horizontal, 2)
    }

    private var overviewSection: some View {
        let active = activeGoals
        let complete = active.filter { isComplete($0) }.count
        return LazyVGrid(columns: Layout.columns(hSizeClass: hSizeClass), spacing: Layout.gridSpacing) {
            StatCard(label: "Active", value: "\(active.count)")
            StatCard(label: "Complete", value: "\(complete)")
            StatCard(label: "Archived", value: "\(archivedGoals.count)")
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
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showArchived.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Text("Archived goals")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.text2)
                    Spacer(minLength: 0)
                    Text("\(archivedGoals.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.text2)
                    Image(systemName: showArchived ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.text2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.bg)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
            }
            .buttonStyle(.plain)

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
        goal.currentValue(from: store.sessions)
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

}
