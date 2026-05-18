import SwiftUI
import UIKit

enum AppTab: String, CaseIterable, Hashable {
    case dashboard, log, drills, goals, settings

    var label: String {
        switch self {
        case .dashboard: return NSLocalizedString("Dashboard", comment: "")
        case .log: return NSLocalizedString("Log", comment: "")
        case .drills: return NSLocalizedString("Drills", comment: "")
        case .goals: return NSLocalizedString("Goals", comment: "")
        case .settings: return NSLocalizedString("Settings", comment: "")
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "chart.line.uptrend.xyaxis"
        case .log: return "plus.circle"
        case .drills: return "circle.grid.3x3.fill"
        case .goals: return "target"
        case .settings: return "gearshape"
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var logStore: SessionLogStore
    @EnvironmentObject private var goalsStore: GoalsStore
    @EnvironmentObject private var profileStore: PlayerProfileStore
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: AppTab = .dashboard
    @State private var showOnboarding = false
    @State private var showLegacyPrompt = false
    @State private var onboardingEvaluated = false
    @State private var isInLiteMode: Bool = false
    @State private var completedGoalCelebration: Goal?
    @State private var completedGoalResetPrompt: Goal?
    @State private var completedGoalResetDraft: GoalDraft?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                currentContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                if showLegacyPrompt {
                    OnboardingLegacyPrompt(
                        onPersonalize: {
                            profileStore.markLegacyPromptSeen()
                            showLegacyPrompt = false
                            showOnboarding = true
                        },
                        onNotNow: {
                            profileStore.markLegacyPromptSeen()
                            showLegacyPrompt = false
                        }
                    )
                    .zIndex(15)
                }

                if showOnboarding {
                    OnboardingFlow(
                        initialProfile: profileStore.profile,
                        onSkip: {
                            profileStore.skipOnboarding()
                            showOnboarding = false
                        },
                        onComplete: { profile, createStarter in
                            profileStore.completeOnboarding(profile)
                            if createStarter {
                                let starter = goalsStore.starterGoals(from: profile)
                                goalsStore.applyStarterGoals(starter, replaceExistingStarter: false)
                            }
                            showOnboarding = false
                        }
                    )
                    .zIndex(20)
                }

                if let goal = completedGoalCelebration {
                    GoalCelebrationOverlay(goal: goal)
                        .zIndex(25)
                }

                if let goal = completedGoalResetPrompt {
                    GoalResetPrompt(goal: goal,
                                    onReset: {
                                        goalsStore.markCompletionPromptShown(goal)
                                        completedGoalResetPrompt = nil
                                        selectedTab = .goals
                                        completedGoalResetDraft = GoalDraft(resetFrom: goal)
                                    },
                                    onLater: {
                                        goalsStore.markCompletionPromptShown(goal)
                                        completedGoalResetPrompt = nil
                                    })
                    .zIndex(26)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !showOnboarding && !isInLiteMode && !shouldHideTabBar(size: geo.size) {
                    AppTabBar(selection: $selectedTab)
                        .id("tabbar-\(themeStore.selectedTheme.rawValue)")
                }
            }
            .onPreferenceChange(LogLiteModeKey.self) { value in
                isInLiteMode = value
            }
            .id("root-theme-\(themeStore.selectedTheme.rawValue)")
            .background(Theme.bg.ignoresSafeArea())
            .preferredColorScheme(themeStore.selectedTheme.scheme)
            .task {
                evaluateOnboardingIfNeeded()
                reconcileGoalCompletions()
            }
            .sheet(item: $completedGoalResetDraft) { draft in
                GoalEditorSheet(draft: draft) { updated in
                    saveGoalDraft(updated)
                }
            }
            .onChange(of: store.isLoading) { _ in
                evaluateOnboardingIfNeeded()
            }
            .onChange(of: store.sessions.count) { _ in
                evaluateOnboardingIfNeeded()
            }
            .onChange(of: store.sessions) { _ in
                reconcileGoalCompletions()
            }
            .onChange(of: logStore.currentSession) { _ in
                reconcileGoalCompletions()
            }
            .onChange(of: goalsStore.goals.count) { _ in
                evaluateOnboardingIfNeeded()
                reconcileGoalCompletions()
            }
            .onChange(of: profileStore.rerunToken) { _ in
                showLegacyPrompt = false
                showOnboarding = true
            }
            .onChange(of: scenePhase) { newPhase in
                guard newPhase == .active else { return }
                reconcileGoalCompletions()
            }
        }
    }

    @ViewBuilder
    private var currentContent: some View {
        switch selectedTab {
        case .dashboard:
            DashboardView()
        case .log:
            NavigationStack { LogView() }
                .appBackSwipeEnabled()
        case .drills:
            NavigationStack { DrillsView(onStartDrill: { selectedTab = .log }) }
                .appBackSwipeEnabled()
        case .goals:
            GoalsView()
        case .settings:
            SettingsView()
        }
    }

    private func evaluateOnboardingIfNeeded() {
        guard !onboardingEvaluated else { return }
        let profile = profileStore.profile
        guard profile.hasCompletedOnboarding == false else {
            onboardingEvaluated = true
            return
        }

        let hasExistingData = !store.sessions.isEmpty || !goalsStore.goals.isEmpty
        if hasExistingData {
            onboardingEvaluated = true
            if profile.hasSeenLegacyPrompt == false {
                showLegacyPrompt = true
            }
            return
        }

        if case .loading = store.syncStatus {
            return
        }

        onboardingEvaluated = true
        showOnboarding = true
    }

    private func shouldHideTabBar(size: CGSize) -> Bool {
        let isLandscape = size.width > size.height || verticalSizeClass == .compact
        let isActiveLogSession = selectedTab == .log && logStore.currentSession != nil
        return isLandscape && isActiveLogSession
    }

    private func reconcileGoalCompletions() {
        let completed = goalsStore.autoCompleteReachedGoals(using: sessionsForGoalCompletion())
        guard canPresentGoalCompletionPrompt else { return }
        guard let goal = completed.first ?? goalsStore.pendingCompletionPrompt() else { return }
        presentCompletedGoal(goal)
    }

    private var canPresentGoalCompletionPrompt: Bool {
        !showOnboarding
            && !showLegacyPrompt
            && completedGoalCelebration == nil
            && completedGoalResetPrompt == nil
            && !(selectedTab == .log && logStore.currentSession != nil)
    }

    private func presentCompletedGoal(_ goal: Goal) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
            completedGoalCelebration = goal
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            guard completedGoalCelebration?.id == goal.id else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                completedGoalCelebration = nil
                completedGoalResetPrompt = goal
            }
        }
    }

    private func sessionsForGoalCompletion() -> [Session] {
        guard let activeSession = logStore.currentSession else {
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

    private func saveGoalDraft(_ draft: GoalDraft) {
        if let originalID = draft.originalID,
           let goal = goalsStore.goals.first(where: { $0.id == originalID }) {
            var next = goal
            next.title = draft.title
            next.metric = draft.metric
            next.window = draft.window
            next.target = draft.target
            next.valueStyle = draft.valueStyle
            next.averageBasis = draft.averageBasis
            next.sessionScope = draft.sessionScope
            next.notes = draft.notes
            goalsStore.update(next)
        } else {
            goalsStore.add(draft.makeGoal())
        }
    }
}
