import SwiftUI

struct LogStartView: View {
    @EnvironmentObject private var historyStore: DataStore
    @EnvironmentObject private var opponentStore: OpponentStore
    @EnvironmentObject private var store: SessionLogStore
    @Binding var label: String
    @State private var sessionDate: Date = Date()
    @State private var game: String = "8ball"
    @State private var opponent: String = ""
    @State private var sessionMode: String = "match"
    @State private var selectedDrillID: String = DrillLibrary.templates.first?.id ?? ""
    @State private var selectedDifficulty: DrillDifficultyLevel = .standard
    @State private var targetCount: Int = 3
    @State private var showOpponentPicker: Bool = false
    @State private var showDrillSelector: Bool = false
    @State private var drillSearchText: String = ""
    @State private var showAdvancedMatchOptions: Bool = false
    @State private var raceToEnabled: Bool = false
    @State private var raceTo: Int = 9
    @FocusState private var opponentFocused: Bool

    private var selectedTemplate: DrillTemplate? {
        DrillLibrary.template(id: selectedDrillID) ?? DrillLibrary.templates.first
    }

    private var selectedDrillDifficulty: DrillDifficulty {
        selectedTemplate?.difficultyLevels.first(where: { $0.level == selectedDifficulty })
            ?? selectedTemplate?.standardDifficulty
            ?? DrillDifficulty(level: .standard, ballCount: 5, constraint: "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            modeCard
            if sessionMode == "match" {
                detailsCard
                gameCard
            } else {
                practiceCard
                targetCard
            }
            startButton
        }
        .padding(4)
        .onChange(of: selectedDrillID) { _ in
            selectedDifficulty = selectedTemplate?.standardDifficulty.level ?? .standard
        }
        .sheet(isPresented: $showDrillSelector) {
            DrillSelectorSheet(
                selectedDrillID: $selectedDrillID,
                searchText: $drillSearchText
            )
        }
    }

    private var header: some View {
        HStack {
            Text(LogStartCopy.headerTitle(mode: sessionMode))
                .font(.title2.bold())
                .foregroundColor(Theme.text)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 2)
        .padding(.top, 4)
    }

    private var modeCard: some View {
        HStack(spacing: 8) {
            Text("Mode")
                .font(.caption.weight(.semibold))
                .foregroundColor(Theme.muted)
            CompactModeButton(title: "Match", isOn: sessionMode == "match", color: Theme.blue) {
                sessionMode = "match"
            }
            CompactModeButton(title: "Practice", isOn: sessionMode == "practice", color: Theme.teal) {
                sessionMode = "practice"
            }
        }
        .padding(8)
        .background(Theme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border.opacity(0.75), lineWidth: 0.5))
    }

    private var detailsCard: some View {
        LogSectionCard(title: "Match") {
            VStack(alignment: .leading, spacing: 12) {
                opponentField

                Button {
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                        showAdvancedMatchOptions.toggle()
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "ellipsis.circle")
                            .font(.subheadline.weight(.bold))
                        .foregroundColor(Theme.text2)
                        Text("Advanced")
                            .font(.caption.weight(.bold))
                            .foregroundColor(Theme.text2)
                        Spacer(minLength: 0)
                        if let advancedSummary {
                            Text(advancedSummary)
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(Theme.muted)
                                .lineLimit(1)
                        }
                        Image(systemName: showAdvancedMatchOptions ? "chevron.up" : "chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(Theme.muted)
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 38)
                    .background(Theme.panel2.opacity(0.75))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.6))
                }
                .buttonStyle(.plain)

                if showAdvancedMatchOptions {
                    advancedMatchOptions
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private var advancedMatchOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Session note")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.text2)
                TextField(labelFieldPlaceholder, text: $label)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 12) {
                Label("Date", systemImage: "calendar")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.text2)
                Spacer()
                DatePicker("", selection: $sessionDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
            }

            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $raceToEnabled) {
                    Label("Race to", systemImage: "flag.checkered")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.text2)
                }
                .toggleStyle(.switch)
                .tint(Theme.teal)

                if raceToEnabled {
                    Stepper(value: $raceTo, in: 1...30) {
                        HStack(spacing: 6) {
                            Text("First to")
                                .font(.caption)
                                .foregroundColor(Theme.muted)
                            Text("\(raceTo)")
                                .font(.headline.weight(.black).monospacedDigit())
                                .foregroundColor(Theme.teal)
                            Text("wins")
                                .font(.caption)
                                .foregroundColor(Theme.muted)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(12)
        .background(Theme.panel2.opacity(0.42))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border.opacity(0.85), lineWidth: 0.6))
    }

    private var practiceCard: some View {
        LogSectionCard(title: "Drill") {
            if let selectedTemplate {
                VStack(alignment: .leading, spacing: 14) {
                    Button {
                        showDrillSelector = true
                    } label: {
                        SelectedDrillPickerCard(
                            template: selectedTemplate,
                            accent: logStartDifficultyColor(selectedDrillDifficulty.level)
                        )
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 9) {
                        Text(selectedTemplate.localizedDescription)
                            .font(.caption)
                            .foregroundColor(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 6) {
                            ForEach(Array(selectedTemplate.localizedPrimarySkills.prefix(3)), id: \.self) { skill in
                                Text(skill)
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(logStartSkillColor(skill))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(logStartSkillColor(skill).opacity(0.14))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(logStartSkillColor(skill).opacity(0.3), lineWidth: 0.6))
                            }
                            Spacer(minLength: 0)
                            Text(selectedTemplate.difficultyRangeText)
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(Theme.text2)
                        }
                    }

                    VStack(alignment: .leading, spacing: 9) {
                        HStack {
                            Text("Difficulty")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Theme.text2)
                            Spacer()
                            Text(selectedTemplate.difficultySummary(selectedDrillDifficulty))
                                .font(.caption.weight(.bold))
                                .foregroundColor(logStartDifficultyColor(selectedDrillDifficulty.level))
                        }
                        DifficultyGradientSlider(levels: selectedTemplate.difficultyLevels, selectedLevel: $selectedDifficulty)
                        Text(selectedDrillDifficulty.localizedConstraint)
                            .font(.caption)
                            .foregroundColor(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else {
                Button {
                    showDrillSelector = true
                } label: {
                    Text("Choose a drill")
                        .font(.caption)
                        .foregroundColor(Theme.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Theme.panel2)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var targetCard: some View {
        LogSectionCard(title: "Target") {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 7) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption.weight(.bold))
                            .foregroundColor(Theme.green)
                        Text("Successes")
                            .font(.headline.weight(.bold))
                            .foregroundColor(Theme.green)
                    }
                    Text("Stop the drill when you make the selected number of successful reps.")
                        .font(.caption)
                        .foregroundColor(Theme.text2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(targetSummary)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.green)
                }
                Spacer(minLength: 0)
                SuccessRepWheel(value: $targetCount, range: 1...30)
            }
        }
    }

    private var opponentField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField(opponentFieldPlaceholder, text: $opponent)
                    .focused($opponentFocused)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)
                    .onTapGesture { showOpponentPicker = true }
                    .onChange(of: opponent) { _ in if opponentFocused { showOpponentPicker = true } }

                if !trimmedOpponent.isEmpty {
                    Button {
                        opponent = ""
                        showOpponentPicker = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.muted)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    showOpponentPicker.toggle()
                    if showOpponentPicker { opponentFocused = true }
                } label: {
                    Image(systemName: showOpponentPicker ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.text2)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .frame(height: 38)
            .background(Theme.panel2)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.6))

            if showOpponentPicker && (canCreateOpponent || !filteredOpponentSuggestions.isEmpty) {
                VStack(spacing: 0) {
                    if canCreateOpponent {
                        Button {
                            let created = trimmedOpponentForLookup
                            opponentStore.addOpponent(name: created)
                            opponent = created
                            showOpponentPicker = false
                            opponentFocused = false
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Theme.teal)
                                Text(AppLanguageRuntime.localizedFormat("Create \"%@\"", trimmedOpponentForLookup))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(Theme.text)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 10)
                            .frame(height: 36)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if !filteredOpponentSuggestions.isEmpty { Divider().overlay(Theme.border) }
                    }

                    ForEach(filteredOpponentSuggestions.prefix(6), id: \.self) { name in
                        Button {
                            opponent = name
                            showOpponentPicker = false
                            opponentFocused = false
                        } label: {
                            HStack(spacing: 8) {
                                Text(name)
                                    .font(.subheadline)
                                    .foregroundColor(Theme.text)
                                if isFavoriteOpponent(name) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(Theme.amber)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 10)
                            .frame(height: 34)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if name != filteredOpponentSuggestions.prefix(6).last { Divider().overlay(Theme.border) }
                    }
                }
                .background(Theme.panel2)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.6))
            }
        }
    }

    private var gameCard: some View {
        LogSectionCard(title: "Game") {
            HStack(spacing: 10) {
                SessionChoiceCard(title: "8-ball", ballNumber: 8, isOn: game == "8ball", color: Theme.green) { game = "8ball" }
                SessionChoiceCard(title: "9-ball", ballNumber: 9, isOn: game == "9ball", color: Theme.amber) { game = "9ball" }
            }
        }
    }

    private var startButton: some View {
        Button {
            if sessionMode == "practice" {
                guard let selectedTemplate else { return }
                store.startDrillPractice(
                    template: selectedTemplate,
                    difficulty: selectedDrillDifficulty,
                    targetType: "successes",
                    targetCount: targetCount
                )
            } else {
                store.startSession(
                    game: game,
                    label: trimmedLabel,
                    opponent: trimmedOpponent,
                    date: sessionDate,
                    raceTo: raceToEnabled ? raceTo : nil
                )
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(LogStartCopy.startButtonTitle(mode: sessionMode))
                        .font(.headline)
                    Text(summaryText)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
            }
            .foregroundColor(.white)
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(LinearGradient(colors: [Theme.teal.opacity(0.72), Theme.blue.opacity(0.66)], startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.teal.opacity(0.28), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
        .disabled(sessionMode == "practice" && selectedTemplate == nil)
        .opacity(sessionMode == "practice" && selectedTemplate == nil ? 0.55 : 1)
    }

    private var labelFieldPlaceholder: String { NSLocalizedString("Session note (optional)", comment: "") }
    private var opponentFieldPlaceholder: String { NSLocalizedString("Opponent (optional)", comment: "") }
    private var trimmedLabel: String { label.trimmingCharacters(in: .whitespaces) }

    private var summaryText: String {
        if sessionMode == "practice" {
            return LogStartCopy.practiceSummary(
                templateTitle: selectedTemplate?.title,
                difficultySummary: selectedTemplate?.difficultySummary(selectedDrillDifficulty) ?? selectedDrillDifficulty.summaryText,
                targetSummary: targetSummary
            )
        }
        return LogStartCopy.matchSummary(
            gameText: game == "8ball" ? "8-ball" : "9-ball",
            raceToEnabled: raceToEnabled,
            raceTo: raceTo,
            opponent: trimmedOpponent,
            dateSummary: dateSummary
        )
    }

    private var targetSummary: String {
        AppLanguageRuntime.localizedFormat("%lld successful reps", targetCount)
    }

    private var dateSummary: String { AppFormatters.shortDate(sessionDate) }
    private var advancedSummary: String? {
        LogStartCopy.advancedSummary(noteIsSet: !trimmedLabel.isEmpty, raceToEnabled: raceToEnabled, raceTo: raceTo)
    }
    private var trimmedOpponent: String { opponent.trimmingCharacters(in: .whitespaces) }

    private var opponentSuggestions: [String] {
        var names = opponentStore.availableNames(from: historyStore.sessions).filter { $0 != "All opponents" }
        if names.contains(where: { $0.caseInsensitiveCompare("Other") == .orderedSame }) == false { names.append("Other") }
        return names
    }

    private var filteredOpponentSuggestions: [String] {
        let q = opponent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return opponentSuggestions }
        let exact = opponentSuggestions.first { $0.caseInsensitiveCompare(q) == .orderedSame }
        let starts = opponentSuggestions.filter { $0.range(of: q, options: [.caseInsensitive, .anchored]) != nil }
        let contains = opponentSuggestions.filter { $0.range(of: q, options: .caseInsensitive) != nil && starts.contains($0) == false }
        let merged = starts + contains
        if let exact, merged.contains(exact) { return [exact] + merged.filter { $0 != exact } }
        return merged
    }

    private var trimmedOpponentForLookup: String { opponent.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var canCreateOpponent: Bool {
        let candidate = trimmedOpponentForLookup
        guard !candidate.isEmpty else { return false }
        if candidate.caseInsensitiveCompare("Other") == .orderedSame { return false }
        return opponentSuggestions.contains(where: { $0.caseInsensitiveCompare(candidate) == .orderedSame }) == false
    }

    private func isFavoriteOpponent(_ name: String) -> Bool {
        opponentStore.profile(for: name)?.isFavorite == true
    }
}
