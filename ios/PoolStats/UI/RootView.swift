import SwiftUI
import UIKit

enum AppTab: String, CaseIterable, Hashable {
    case dashboard, log, drills, goals, settings

    var label: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .log: return "Log"
        case .drills: return "Drills"
        case .goals: return "Goals"
        case .settings: return "Settings"
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
    @State private var selectedTab: AppTab = .dashboard
    @State private var showOnboarding = false
    @State private var showLegacyPrompt = false
    @State private var onboardingEvaluated = false
    @State private var isInLiteMode: Bool = false

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
            }
            .onChange(of: store.isLoading) { _ in
                evaluateOnboardingIfNeeded()
            }
            .onChange(of: store.sessions.count) { _ in
                evaluateOnboardingIfNeeded()
            }
            .onChange(of: goalsStore.goals.count) { _ in
                evaluateOnboardingIfNeeded()
            }
            .onChange(of: profileStore.rerunToken) { _ in
                showLegacyPrompt = false
                showOnboarding = true
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
}
