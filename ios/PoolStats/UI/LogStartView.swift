import SwiftUI

struct LogStartView: View {
    @EnvironmentObject private var historyStore: DataStore
    @EnvironmentObject private var opponentStore: OpponentStore
    @EnvironmentObject private var store: SessionLogStore
    @Binding var label: String
    @State private var sessionDate: Date = Date()
    @State private var sessionType: String = "match"
    @State private var game: String = "8ball"
    @State private var opponent: String = ""
    @State private var showOpponentPicker: Bool = false
    @FocusState private var opponentFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            detailsCard
            sessionTypeCard
            gameCard
            startButton
        }
        .padding(4)
    }

    private var header: some View {
        HStack {
            Text("Log a session")
                .font(.title2.bold())
                .foregroundColor(Theme.text)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 2)
        .padding(.top, 4)
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

    private var opponentField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField(opponentFieldPlaceholder, text: $opponent)
                    .focused($opponentFocused)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)
                    .onTapGesture {
                        showOpponentPicker = true
                    }
                    .onChange(of: opponent) { _ in
                        if opponentFocused { showOpponentPicker = true }
                    }

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
                    if showOpponentPicker {
                        opponentFocused = true
                    }
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

                        if !filteredOpponentSuggestions.isEmpty {
                            Divider().overlay(Theme.border)
                        }
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

                        if name != filteredOpponentSuggestions.prefix(6).last {
                            Divider().overlay(Theme.border)
                        }
                    }
                }
                .background(Theme.panel2)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 0.6))
            }
        }
    }

    private var sessionTypeCard: some View {
        LogSectionCard(title: "Session type") {
            HStack(spacing: 10) {
                SessionChoiceCard(
                    title: "Match",
                    isOn: sessionType == "match",
                    color: Theme.teal
                ) {
                    sessionType = "match"
                }
                SessionChoiceCard(
                    title: "Practice",
                    isOn: sessionType == "practice",
                    color: Theme.purple
                ) {
                    sessionType = "practice"
                    label = ""
                }
            }
        }
    }

    private var gameCard: some View {
        LogSectionCard(title: "Game") {
            HStack(spacing: 10) {
                SessionChoiceCard(
                    title: "8-ball",
                    isOn: game == "8ball",
                    color: Theme.green
                ) {
                    game = "8ball"
                }
                SessionChoiceCard(
                    title: "9-ball",
                    isOn: game == "9ball",
                    color: Theme.amber
                ) {
                    game = "9ball"
                }
            }
        }
    }

    private var startButton: some View {
        Button {
            store.startSession(
                game: game,
                type: sessionType,
                label: trimmedLabel,
                opponent: trimmedOpponent,
                date: sessionDate
            )
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Start session")
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
            .background(
                LinearGradient(
                    colors: sessionType == "match" ? [Theme.teal, Theme.blue] : [Theme.purple, Theme.blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    private var labelFieldPlaceholder: String {
        sessionType == "practice" ? "Practice note (optional)" : "Session note (optional)"
    }

    private var opponentFieldPlaceholder: String {
        sessionType == "practice" ? "Practice partner (optional)" : "Opponent (optional)"
    }

    private var trimmedLabel: String {
        label.trimmingCharacters(in: .whitespaces)
    }

    private var summaryText: String {
        let mode = sessionType == "practice" ? "Practice" : "Match"
        let gameText = game == "8ball" ? "8-ball" : "9-ball"
        let segments = [mode, gameText, trimmedOpponent.isEmpty ? nil : "vs \(trimmedOpponent)", dateSummary]
        return segments.compactMap { $0 }.joined(separator: " · ")
    }

    private var dateSummary: String {
        AppFormatters.shortDate(sessionDate)
    }

    private var trimmedOpponent: String {
        opponent.trimmingCharacters(in: .whitespaces)
    }

    private var opponentSuggestions: [String] {
        opponentStore.availableNames(from: historyStore.sessions).filter { $0 != "All opponents" }
    }

    private var filteredOpponentSuggestions: [String] {
        let q = opponent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return opponentSuggestions }
        let exact = opponentSuggestions.first { $0.caseInsensitiveCompare(q) == .orderedSame }
        let starts = opponentSuggestions.filter { $0.range(of: q, options: [.caseInsensitive, .anchored]) != nil }
        let contains = opponentSuggestions.filter {
            $0.range(of: q, options: .caseInsensitive) != nil && starts.contains($0) == false
        }
        let merged = starts + contains
        if let exact, merged.contains(exact) {
            return [exact] + merged.filter { $0 != exact }
        }
        return merged
    }

    private var trimmedOpponentForLookup: String {
        opponent.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canCreateOpponent: Bool {
        let candidate = trimmedOpponentForLookup
        guard !candidate.isEmpty else { return false }
        return opponentSuggestions.contains(where: {
            $0.caseInsensitiveCompare(candidate) == .orderedSame
        }) == false
    }

    private func isFavoriteOpponent(_ name: String) -> Bool {
        opponentStore.profile(for: name)?.isFavorite == true
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
