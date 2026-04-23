import SwiftUI

// MARK: - Legacy prompt (existing users)

struct OnboardingLegacyPrompt: View {
    let onPersonalize: () -> Void
    let onNotNow: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture(perform: onNotNow)

            VStack {
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Theme.purple.opacity(0.15))
                                .frame(width: 48, height: 48)
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(Theme.purple)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Personalize your profile")
                                .font(.headline)
                                .foregroundColor(Theme.text)
                            Text("Takes about 30 seconds")
                                .font(.caption)
                                .foregroundColor(Theme.muted)
                        }
                    }

                    Text("Set your skill level and dedication so your Dashboard Fargo estimate and starter goals are calibrated to you.")
                        .font(.subheadline)
                        .foregroundColor(Theme.text2)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 10) {
                        Button(action: onPersonalize) {
                            Text("Set up my profile")
                                .font(.headline)
                                .foregroundColor(Theme.bg)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Theme.purple)
                                .cornerRadius(14)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Button(action: onNotNow) {
                            Text("Not now")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(Theme.text2)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
                .background(Theme.panel)
                .cornerRadius(24)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.border, lineWidth: 0.5))
                .padding(.horizontal, Layout.pagePadding)
                .padding(.bottom, 24)
            }
        }
        .transition(.opacity)
    }
}

// MARK: - Full-page onboarding flow

struct OnboardingFlow: View {
    let initialProfile: PlayerProfile
    let onSkip: () -> Void
    let onComplete: (PlayerProfile, Bool) -> Void

    @State private var step = 0
    @State private var profile: PlayerProfile
    @State private var useCustomFargo = false
    @State private var customFargoText = ""
    @State private var createStarterGoals = true
    @State private var showFargoInfo = false

    private let totalSteps = 3

    init(initialProfile: PlayerProfile, onSkip: @escaping () -> Void, onComplete: @escaping (PlayerProfile, Bool) -> Void) {
        self.initialProfile = initialProfile
        self.onSkip = onSkip
        self.onComplete = onComplete
        _profile = State(initialValue: initialProfile)
        _customFargoText = State(initialValue: "\(initialProfile.clampedBaseline)")
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            if step == 0 {
                welcomeScreen
                    .transition(.opacity)
            } else {
                setupScreen
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.28), value: step)
    }

    // MARK: Welcome

    private var welcomeScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(Theme.purple.opacity(0.12))
                        .frame(width: 100, height: 100)
                    Circle()
                        .fill(Theme.purple.opacity(0.07))
                        .frame(width: 130, height: 130)
                    Image(systemName: "target")
                        .font(.system(size: 46, weight: .semibold))
                        .foregroundColor(Theme.purple)
                }

                VStack(spacing: 10) {
                    Text("Pool Stats")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(Theme.text)
                    Text("Track your game.\nFind your leaks.")
                        .font(.title3)
                        .foregroundColor(Theme.text2)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }

            Spacer()

            VStack(spacing: 14) {
                Button {
                    withAnimation(.easeInOut(duration: 0.28)) { step = 1 }
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(Theme.bg)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.purple)
                        .cornerRadius(16)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button(action: onSkip) {
                    Text("Skip setup")
                        .font(.subheadline)
                        .foregroundColor(Theme.text2)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Layout.pagePadding)
            .padding(.bottom, 48)
        }
        .padding(.horizontal, Layout.pagePadding)
    }

    // MARK: Setup screen shell

    private var setupScreen: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    stepContent
                        .padding(.horizontal, Layout.pagePadding)
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                }
            }

            bottomBar
        }
    }

    private var topBar: some View {
        HStack(alignment: .center, spacing: 0) {
            progressDots
            Spacer(minLength: 12)
            Button(action: onSkip) {
                Text("Skip")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.text2)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.panel2)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.border, lineWidth: 0.5))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Layout.pagePadding)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(1...totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? Theme.purple : Theme.border)
                    .frame(width: i == step ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: step)
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            Button(action: advance) {
                Text(step < totalSteps ? "Continue" : "Finish setup")
                    .font(.headline)
                    .foregroundColor(Theme.bg)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Theme.purple)
                    .cornerRadius(16)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if step > 1 {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { step -= 1 }
                } label: {
                    Text("Back")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Theme.text2)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Theme.panel)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.5))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Layout.pagePadding)
        .padding(.top, 12)
        .padding(.bottom, 40)
    }

    private func advance() {
        if step < totalSteps {
            withAnimation(.easeInOut(duration: 0.25)) { step += 1 }
        } else {
            var final = profile
            final.baselineFargo = useCustomFargo
                ? min(max(Int(customFargoText) ?? profile.skillLevel.defaultFargo, 0), 850)
                : profile.skillLevel.defaultFargo
            onComplete(final, createStarterGoals)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 1: skillStep
        case 2: dedicationStep
        case 3: gameAndFrequencyStep
        default: EmptyView()
        }
    }

    // MARK: Step 1 — Skill level

    private var skillStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's your\ncurrent level?")
                        .font(.largeTitle.bold())
                        .foregroundColor(Theme.text)
                    Text("Calibrates your Fargo baseline and goal targets.")
                        .font(.subheadline)
                        .foregroundColor(Theme.text2)
                }
                Spacer(minLength: 0)
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { showFargoInfo.toggle() }
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20))
                        .foregroundColor(showFargoInfo ? Theme.purple : Theme.muted)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }

            if showFargoInfo {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("What is Fargo Rating?")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Theme.text)
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) { showFargoInfo = false }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.muted)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    Text("Fargo is the standard handicap system for pool — like a golf handicap but for billiards. Ratings run from ~100 (complete beginner) to 850+ (world-class). It's computed from match results and updates over time. Pool Stats uses your Fargo as a baseline to track improvement on your Dashboard.")
                        .font(.caption)
                        .foregroundColor(Theme.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(Theme.panel2)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            VStack(spacing: 10) {
                ForEach(SkillLevel.allCases) { level in
                    let selected = profile.skillLevel == level
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            profile.skillLevel = level
                            if !useCustomFargo {
                                profile.baselineFargo = level.defaultFargo
                                customFargoText = "\(level.defaultFargo)"
                            }
                        }
                    } label: {
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(level.label)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(selected ? Theme.text : Theme.text2)
                                Text("Fargo \(level.fargoRange)")
                                    .font(.caption2)
                                    .foregroundColor(selected ? Theme.purple : Theme.muted)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22))
                                .foregroundColor(selected ? Theme.purple : Theme.border)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(selected ? Theme.purple.opacity(0.10) : Theme.panel)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selected ? Theme.purple : Theme.border,
                                        lineWidth: selected ? 1.4 : 0.5)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .opacity(useCustomFargo ? 0.4 : 1)
            .allowsHitTesting(!useCustomFargo)
            .animation(.easeInOut(duration: 0.18), value: useCustomFargo)

            VStack(alignment: .leading, spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        useCustomFargo.toggle()
                        if !useCustomFargo {
                            profile.baselineFargo = profile.skillLevel.defaultFargo
                            customFargoText = "\(profile.baselineFargo)"
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: useCustomFargo ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundColor(useCustomFargo ? Theme.purple : Theme.muted)
                        Text("I know my exact Fargo rating")
                            .font(.subheadline)
                            .foregroundColor(Theme.text2)
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if useCustomFargo {
                    HStack(spacing: 12) {
                        Text("My Fargo")
                            .font(.subheadline)
                            .foregroundColor(Theme.text2)
                        Spacer(minLength: 0)
                        TextField("400", text: $customFargoText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.title3.monospacedDigit().weight(.semibold))
                            .foregroundColor(Theme.text)
                            .frame(width: 80)
                            .onChange(of: customFargoText) { value in
                                let filtered = value.filter(\.isNumber)
                                if filtered != value { customFargoText = filtered }
                                profile.baselineFargo = min(max(Int(filtered) ?? profile.skillLevel.defaultFargo, 0), 850)
                            }
                        Text("/ 850")
                            .font(.caption)
                            .foregroundColor(Theme.muted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Theme.panel)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.purple.opacity(0.5), lineWidth: 1))
                }
            }
        }
    }

    // MARK: Step 2 — Dedication

    private var dedicationStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 8) {
                Text("How serious are\nyou about improving?")
                    .font(.largeTitle.bold())
                    .foregroundColor(Theme.text)
                Text("Sets the intensity of your starter goals.")
                    .font(.subheadline)
                    .foregroundColor(Theme.text2)
            }

            DedicationGauge(selection: $profile.dedication)
                .padding(.top, 4)
        }
    }

    // MARK: Step 3 — Game, frequency, and goals

    private var gameAndFrequencyStep: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                Text("How do you play?")
                    .font(.largeTitle.bold())
                    .foregroundColor(Theme.text)
                Text("Scopes your goals and stats to your game.")
                    .font(.subheadline)
                    .foregroundColor(Theme.text2)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Primary game")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.text)
                HStack(spacing: 10) {
                    ForEach(PrimaryGame.allCases) { game in
                        let selected = profile.primaryGame == game
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                profile.primaryGame = game
                            }
                        } label: {
                            Text(game.label)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(selected ? Theme.text : Theme.text2)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(selected ? Theme.teal.opacity(0.10) : Theme.panel)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(selected ? Theme.teal : Theme.border,
                                                lineWidth: selected ? 1.4 : 0.5)
                                )
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("How often do you play a week?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.text)
                HStack(spacing: 10) {
                    ForEach(FrequencyBand.allCases) { band in
                        let selected = profile.weeklyFrequencyBand == band
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                profile.weeklyFrequencyBand = band
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Text(band.frequency)
                                    .font(.title3.weight(.bold).monospacedDigit())
                                    .foregroundColor(selected ? Theme.text : Theme.text2)
                                Text(band.sublabel)
                                    .font(.caption2.weight(.medium))
                                    .foregroundColor(selected ? Theme.amber : Theme.muted)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(selected ? Theme.amber.opacity(0.10) : Theme.panel)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(selected ? Theme.amber : Theme.border,
                                            lineWidth: selected ? 1.4 : 0.5)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    createStarterGoals.toggle()
                }
            } label: {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Create starter goals")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Theme.text)
                        Text("Personalized goals based on your profile.")
                            .font(.caption)
                            .foregroundColor(Theme.text2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    TogglePill(isOn: createStarterGoals)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Theme.panel)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.5))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Dedication gauge

struct DedicationGauge: View {
    @Binding var selection: DedicationLevel

    private let cases = DedicationLevel.allCases
    private let barWidth: CGFloat = 64
    private let gaugeHeight: CGFloat = 220

    @State private var dragBaseIndex: Int = 0
    @State private var dragging = false

    private var selectedIndex: Int {
        cases.firstIndex(of: selection) ?? 0
    }

    private var fillFraction: CGFloat {
        CGFloat(selectedIndex + 1) / CGFloat(cases.count)
    }

    private var accentColor: Color {
        switch selection {
        case .justForFun: return Theme.border
        case .maybe: return Theme.teal.opacity(0.9)
        case .neutral: return Theme.teal
        case .yes: return Theme.green
        case .veryMuch: return Theme.purple
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(selection.label)
                    .font(.title3.weight(.bold))
                    .foregroundColor(selection == .justForFun ? Theme.text2 : accentColor)
                    .animation(.easeInOut(duration: 0.2), value: selection)
                Text("Drag up or down to adjust")
                    .font(.caption)
                    .foregroundColor(Theme.muted)
            }

            HStack(alignment: .center, spacing: 20) {
                gaugeBar
                tickLabels
                Spacer(minLength: 0)
            }
        }
    }

    private var gaugeBar: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.panel2)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.border, lineWidth: 0.5))

            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.5), accentColor],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(height: gaugeHeight * fillFraction)
                .animation(.spring(response: 0.38, dampingFraction: 0.72), value: selection)
        }
        .frame(width: barWidth, height: gaugeHeight)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 2)
                .onChanged { value in
                    if !dragging {
                        dragging = true
                        dragBaseIndex = selectedIndex
                    }
                    let segH = gaugeHeight / CGFloat(cases.count)
                    let delta = -value.translation.height
                    let newIndex = max(0, min(cases.count - 1,
                        Int(round(Double(dragBaseIndex) + Double(delta) / Double(segH)))))
                    if newIndex != selectedIndex {
                        selection = cases[newIndex]
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    }
                }
                .onEnded { _ in
                    dragging = false
                }
        )
    }

    private var tickLabels: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(cases.reversed()) { level in
                let idx = cases.firstIndex(of: level)!
                let isActive = idx <= selectedIndex
                let isSelected = selection == level

                HStack(spacing: 8) {
                    Capsule()
                        .fill(isActive ? accentColor : Theme.border)
                        .frame(width: isSelected ? 14 : 8, height: 2.5)
                    Text(level.label)
                        .font(isSelected ? .subheadline.weight(.semibold) : .caption)
                        .foregroundColor(isSelected ? (level == .justForFun ? Theme.text2 : accentColor)
                                                   : (isActive ? Theme.text2 : Theme.muted))
                }
                .animation(.easeInOut(duration: 0.15), value: selection)

                if level != cases.first {
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(height: gaugeHeight)
    }
}

// MARK: - Toggle pill

struct TogglePill: View {
    let isOn: Bool

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? Theme.green : Theme.panel2)
                .frame(width: 50, height: 30)
                .overlay(Capsule().stroke(isOn ? Theme.green.opacity(0.6) : Theme.border, lineWidth: 0.5))
            Circle()
                .fill(Color.white)
                .frame(width: 24, height: 24)
                .padding(.horizontal, 3)
                .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
        }
    }
}
