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
    @State private var targetType: String = "successes"
    @State private var targetCount: Int = 3
    @State private var showOpponentPicker: Bool = false
    @FocusState private var opponentFocused: Bool

    private var selectedTemplate: DrillTemplate {
        DrillLibrary.template(id: selectedDrillID) ?? DrillLibrary.templates[0]
    }

    private var selectedDrillDifficulty: DrillDifficulty {
        selectedTemplate.difficultyLevels.first(where: { $0.level == selectedDifficulty }) ?? selectedTemplate.standardDifficulty
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
            selectedDifficulty = selectedTemplate.standardDifficulty.level
        }
    }

    private var header: some View {
        HStack {
            Text(sessionMode == "match" ? "Log a match" : "Start practice")
                .font(.title2.bold())
                .foregroundColor(Theme.text)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 2)
        .padding(.top, 4)
    }

    private var modeCard: some View {
        LogSectionCard(title: "Mode") {
            HStack(spacing: 10) {
                SessionChoiceCard(title: "Match", isOn: sessionMode == "match", color: Theme.blue) { sessionMode = "match" }
                SessionChoiceCard(title: "Practice", isOn: sessionMode == "practice", color: Theme.teal) { sessionMode = "practice" }
            }
        }
    }

    private var detailsCard: some View {
        LogSectionCard(title: "Session details") {
            VStack(alignment: .leading, spacing: 12) {
                opponentField

                TextField(labelFieldPlaceholder, text: $label)
                    .textFieldStyle(.roundedBorder)

                HStack(spacing: 12) {
                    Text("Date")
                        .font(.caption)
                        .foregroundColor(Theme.muted)
                    Spacer()
                    DatePicker("", selection: $sessionDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }
            }
        }
    }

    private var practiceCard: some View {
        LogSectionCard(title: "Drill") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Drill", selection: $selectedDrillID) {
                    ForEach(DrillLibrary.templates) { template in
                        Text(template.title).tag(template.id)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.teal)

                Text(selectedTemplate.description)
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Difficulty")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Theme.text2)
                        Spacer()
                        Text("\(selectedDrillDifficulty.level.label) · \(selectedDrillDifficulty.ballCount) balls")
                            .font(.caption.weight(.bold))
                            .foregroundColor(difficultyColor(for: selectedDrillDifficulty.level))
                    }
                    HStack(spacing: 7) {
                        ForEach(selectedTemplate.difficultyLevels) { difficulty in
                            Button {
                                selectedDifficulty = difficulty.level
                            } label: {
                                Text(difficulty.level.label.prefix(1))
                                    .font(.caption.weight(.black))
                                    .foregroundColor(selectedDifficulty == difficulty.level ? .black.opacity(0.82) : difficultyColor(for: difficulty.level))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 34)
                                    .background(selectedDifficulty == difficulty.level ? difficultyColor(for: difficulty.level) : difficultyColor(for: difficulty.level).opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(difficultyColor(for: difficulty.level).opacity(0.35), lineWidth: 0.7))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var targetCard: some View {
        LogSectionCard(title: "Target") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    SessionChoiceCard(title: "Successes", isOn: targetType == "successes", color: Theme.green) { targetType = "successes" }
                    SessionChoiceCard(title: "Attempts", isOn: targetType == "attempts", color: Theme.amber) { targetType = "attempts" }
                }
                Stepper(value: $targetCount, in: 1...50) {
                    HStack {
                        Text(targetType == "successes" ? "Successful reps" : "Total attempts")
                            .font(.caption)
                            .foregroundColor(Theme.muted)
                        Spacer()
                        Text("\(targetCount)")
                            .font(.headline.weight(.bold).monospacedDigit())
                            .foregroundColor(targetType == "successes" ? Theme.green : Theme.amber)
                    }
                }
                Text(targetSummary)
                    .font(.caption)
                    .foregroundColor(Theme.text2)
                    .fixedSize(horizontal: false, vertical: true)
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
                                Text("Create \"\(trimmedOpponentForLookup)\"")
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
                SessionChoiceCard(title: "8-ball", isOn: game == "8ball", color: Theme.green) { game = "8ball" }
                SessionChoiceCard(title: "9-ball", isOn: game == "9ball", color: Theme.amber) { game = "9ball" }
            }
        }
    }

    private var startButton: some View {
        Button {
            if sessionMode == "practice" {
                store.startDrillPractice(
                    template: selectedTemplate,
                    difficulty: selectedDrillDifficulty,
                    targetType: targetType,
                    targetCount: targetCount
                )
            } else {
                store.startSession(game: game, type: "match", label: trimmedLabel, opponent: trimmedOpponent, date: sessionDate)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(sessionMode == "practice" ? "Start practice" : "Start session")
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
            .background(LinearGradient(colors: [Theme.teal, Theme.blue], startPoint: .leading, endPoint: .trailing))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    private var labelFieldPlaceholder: String { "Session note (optional)" }
    private var opponentFieldPlaceholder: String { "Opponent (optional)" }
    private var trimmedLabel: String { label.trimmingCharacters(in: .whitespaces) }

    private var summaryText: String {
        if sessionMode == "practice" {
            return [selectedTemplate.title, selectedDrillDifficulty.level.label, targetSummary].joined(separator: " · ")
        }
        let gameText = game == "8ball" ? "8-ball" : "9-ball"
        let segments = ["Match", gameText, trimmedOpponent.isEmpty ? nil : "vs \(trimmedOpponent)", dateSummary]
        return segments.compactMap { $0 }.joined(separator: " · ")
    }

    private var targetSummary: String {
        targetType == "successes" ? "\(targetCount) successful reps" : "\(targetCount) attempts"
    }

    private var dateSummary: String { AppFormatters.shortDate(sessionDate) }
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

    private func difficultyColor(for level: DrillDifficultyLevel) -> Color {
        switch level {
        case .beginner: return Theme.green
        case .easy: return Theme.teal
        case .standard: return Theme.amber
        case .hard: return Color.orange
        case .expert: return Theme.red
        }
    }
}

private struct SessionChoiceCard: View {
    let title: String
    let isOn: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isOn ? color : Theme.text)
                Spacer()
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isOn ? color : Theme.muted)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(isOn ? color.opacity(0.15) : Theme.panel)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(isOn ? color : Theme.border, lineWidth: 0.8))
        }
        .buttonStyle(.plain)
    }
}
