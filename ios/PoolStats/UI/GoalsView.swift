import SwiftUI

struct GoalsView: View {
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var logStore: SessionLogStore
    @EnvironmentObject private var goalsStore: GoalsStore
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
            VStack(alignment: .leading, spacing: 4) {
                Text("Goals")
                    .font(.title.bold())
                    .foregroundColor(Theme.text)
                Text("Track the habits and outcomes you want to move, not just the sessions you log.")
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Button {
                editorDraft = GoalDraft()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("New")
                        .font(.caption.weight(.semibold))
                }
                .foregroundColor(Theme.text)
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(Theme.panel2)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Theme.border, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
        .padding(.horizontal, 2)
    }

    private var overviewSection: some View {
        let active = activeGoals
        let complete = active.filter { isComplete($0) }.count
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: Layout.gridSpacing) {
                StatCard(label: "Active", value: "\(active.count)")
                StatCard(label: "Complete", value: "\(complete)")
                StatCard(label: "Archived", value: "\(archivedGoals.count)")
            }

            Text(overviewMessage(activeCount: active.count, completeCount: complete))
                .font(.caption)
                .foregroundColor(Theme.muted)
                .padding(.horizontal, 2)
        }
    }

    private var activeGoalsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: "Active goals",
                subtitle: activeGoals.isEmpty
                    ? "Start with one focused metric and let the app track the trend for you."
                    : "\(activeGoals.filter { isComplete($0) }.count) currently at target",
                count: activeGoals.count
            )
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
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Archived goals")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Theme.text2)
                        Text("Completed or paused goals you still want to keep around.")
                            .font(.caption2)
                            .foregroundColor(Theme.muted)
                    }

                    Spacer(minLength: 0)

                    Text("\(archivedGoals.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.text2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.panel)
                        .clipShape(Capsule())

                    Image(systemName: showArchived ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.text2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.panel2.opacity(0.78))
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
            Text("Create one target for matches or practice so your progress has something concrete to chase.")
                .font(.caption)
                .foregroundColor(Theme.muted)
            Button {
                editorDraft = GoalDraft()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                    Text("Create first goal")
                        .font(.caption.weight(.semibold))
                }
                .foregroundColor(Theme.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Theme.purple.opacity(0.18))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Theme.purple.opacity(0.5), lineWidth: 0.8)
                )
            }
            .buttonStyle(.plain)
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
        goal.currentValue(from: sessionsForGoalTracking(goal))
    }

    private func isComplete(_ goal: Goal) -> Bool {
        goal.isComplete(from: sessionsForGoalTracking(goal))
    }

    private func completeGoal(_ goal: Goal) {
        goalsStore.complete(goal, promptShownAt: Date())
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

    private func sectionHeader(title: String, subtitle: String, count: Int) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(title))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.text2)
                Text(LocalizedStringKey(subtitle))
                    .font(.caption2)
                    .foregroundColor(Theme.muted)
            }
            Spacer(minLength: 0)
            Text("\(count)")
                .font(.caption.weight(.semibold))
                .foregroundColor(Theme.text2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.panel2)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 2)
    }

    private func overviewMessage(activeCount: Int, completeCount: Int) -> String {
        if activeCount == 0 {
            return NSLocalizedString("Start with one realistic goal and adjust it once you have a few sessions of data.", comment: "")
        }
        if completeCount == activeCount {
            return NSLocalizedString("Every active goal is currently on target.", comment: "")
        }
        if completeCount == 0 {
            return NSLocalizedString("None of your active goals are at target yet, which is a good signal that the bar is doing real work.", comment: "")
        }
        return AppLanguageRuntime.localizedFormat("%lld of %lld active goals are currently at target.", completeCount, activeCount)
    }

    private func sessionsForGoalTracking(_ goal: Goal) -> [Session] {
        guard goal.metric.updatesFromInProgressSession, let activeSession = logStore.currentSession else {
            return store.sessions
        }

        var merged = store.sessions
        if let index = merged.firstIndex(where: {
            $0.sessionUUID == activeSession.sessionUUID || $0.id == activeSession.id
        }) {
            merged[index] = activeSession
        } else {
            merged.append(activeSession)
        }
        return merged
    }

}
