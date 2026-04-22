import SwiftUI

enum AppTab: String, CaseIterable, Hashable {
    case dashboard, log, history, goals, settings

    var label: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .log: return "Log"
        case .history: return "History"
        case .goals: return "Goals"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "chart.line.uptrend.xyaxis"
        case .log: return "plus.circle"
        case .history: return "clock.arrow.circlepath"
        case .goals: return "target"
        case .settings: return "gearshape"
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var goalsStore: GoalsStore
    @EnvironmentObject private var profileStore: PlayerProfileStore
    @State private var selectedTab: AppTab = .dashboard
    @State private var showOnboarding = false
    @State private var showLegacyPrompt = false
    @State private var onboardingEvaluated = false

    var body: some View {
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
            AppTabBar(selection: $selectedTab)
                .id("tabbar-\(themeStore.selectedTheme.rawValue)")
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

    @ViewBuilder
    private var currentContent: some View {
        switch selectedTab {
        case .dashboard:
            DashboardView()
        case .log:
            LogView()
        case .history:
            NavigationStack { HistoryView() }
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
}

private struct OnboardingLegacyPrompt: View {
    let onPersonalize: () -> Void
    let onNotNow: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack {
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Personalize your profile")
                        .font(.title3.bold())
                        .foregroundColor(Theme.text)
                    Text("Set your baseline Fargo and dedication so Dashboard and goals match your current level.")
                        .font(.caption)
                        .foregroundColor(Theme.muted)

                    HStack(spacing: 8) {
                        Button(action: onNotNow) {
                            Text("Not now")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Theme.text2)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(Theme.panel2)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.6))
                        }
                        .buttonStyle(.plain)

                        Button(action: onPersonalize) {
                            Text("Personalize")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Theme.bg)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(Theme.purple)
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .background(Theme.panel)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 0.6))
                .padding(.horizontal, Layout.pagePadding)
                .padding(.bottom, 18)
            }
        }
    }
}

private struct OnboardingFlow: View {
    let initialProfile: PlayerProfile
    let onSkip: () -> Void
    let onComplete: (PlayerProfile, Bool) -> Void

    @State private var step = 0
    @State private var profile: PlayerProfile
    @State private var useCustomFargo = false
    @State private var customFargoText = ""
    @State private var createStarterGoals = true

    init(initialProfile: PlayerProfile, onSkip: @escaping () -> Void, onComplete: @escaping (PlayerProfile, Bool) -> Void) {
        self.initialProfile = initialProfile
        self.onSkip = onSkip
        self.onComplete = onComplete
        _profile = State(initialValue: initialProfile)
        _customFargoText = State(initialValue: "\(initialProfile.clampedBaseline)")
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack {
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Welcome")
                            .font(.title3.bold())
                            .foregroundColor(Theme.text)
                        Spacer(minLength: 0)
                        Text("Step \(step + 1) / 3")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Theme.text2)
                    }

                    if step == 0 {
                        skillStep
                    } else if step == 1 {
                        dedicationStep
                    } else {
                        gameAndFrequencyStep
                    }

                    actionRow
                }
                .padding(16)
                .background(Theme.panel)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 0.6))
                .padding(.horizontal, Layout.pagePadding)
                .padding(.bottom, 18)
            }
        }
    }

    private var skillStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Current skill level")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.text)
            LazyVGrid(columns: Layout.twoColumn(), spacing: 8) {
                ForEach(SkillLevel.allCases) { level in
                    Button {
                        profile.skillLevel = level
                        if !useCustomFargo {
                            profile.baselineFargo = level.defaultFargo
                            customFargoText = "\(level.defaultFargo)"
                        }
                    } label: {
                        Text(level.label)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(profile.skillLevel == level ? Theme.text : Theme.text2)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(profile.skillLevel == level ? Theme.panel2 : Color.clear)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(profile.skillLevel == level ? Theme.purple : Theme.border, lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                useCustomFargo.toggle()
                if !useCustomFargo {
                    profile.baselineFargo = profile.skillLevel.defaultFargo
                    customFargoText = "\(profile.baselineFargo)"
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: useCustomFargo ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(useCustomFargo ? Theme.purple : Theme.muted)
                    Text("I know my Fargo rating")
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                }
            }
            .buttonStyle(.plain)

            if useCustomFargo {
                HStack(spacing: 8) {
                    Text("Baseline Fargo")
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                    Spacer(minLength: 0)
                    TextField("400", text: $customFargoText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(Theme.text)
                        .frame(width: 72)
                        .onChange(of: customFargoText) { value in
                            let filtered = value.filter(\.isNumber)
                            if filtered != value { customFargoText = filtered }
                            profile.baselineFargo = min(max(Int(filtered) ?? profile.skillLevel.defaultFargo, 0), 850)
                        }
                }
                .padding(10)
                .background(Theme.panel2)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.5))
            } else {
                Text("Mapped baseline: \(profile.skillLevel.defaultFargo)")
                    .font(.caption2)
                    .foregroundColor(Theme.text2)
            }
        }
    }

    private var dedicationStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How dedicated are you to improving right now?")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.text)

            LazyVGrid(columns: Layout.twoColumn(), spacing: 8) {
                ForEach(DedicationLevel.allCases) { level in
                    Button {
                        profile.dedication = level
                    } label: {
                        Text(level.label)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(profile.dedication == level ? Theme.text : Theme.text2)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(profile.dedication == level ? Theme.teal.opacity(0.15) : Color.clear)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(profile.dedication == level ? Theme.teal : Theme.border, lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("This sets starter goal intensity.")
                .font(.caption2)
                .foregroundColor(Theme.muted)
        }
    }

    private var gameAndFrequencyStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Primary game")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.text)
            SegmentedRow(items: PrimaryGame.allCases, selection: $profile.primaryGame) { $0.label }

            Text("Weekly playing frequency")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.text)
            SegmentedRow(items: FrequencyBand.allCases, selection: $profile.weeklyFrequencyBand) { $0.label }

            Button {
                createStarterGoals.toggle()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: createStarterGoals ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(createStarterGoals ? Theme.green : Theme.muted)
                    Text("Create starter goals now")
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button(action: onSkip) {
                Text("Skip")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.text2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Theme.panel2)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.6))
            }
            .buttonStyle(.plain)

            if step > 0 {
                Button {
                    step -= 1
                } label: {
                    Text("Back")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.text2)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(Theme.panel2)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.6))
                }
                .buttonStyle(.plain)
            }

            Button {
                if step < 2 {
                    step += 1
                } else {
                    var final = profile
                    final.baselineFargo = useCustomFargo ? min(max(Int(customFargoText) ?? profile.skillLevel.defaultFargo, 0), 850) : profile.skillLevel.defaultFargo
                    onComplete(final, createStarterGoals)
                }
            } label: {
                Text(step < 2 ? "Continue" : "Finish")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Theme.purple)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }
}
