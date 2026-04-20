import SwiftUI

struct LogStartView: View {
    @EnvironmentObject private var store: SessionLogStore
    @Binding var label: String
    @State private var sessionDate: Date = Date()
    @State private var sessionType: String = "match"
    @State private var game: String = "8ball"

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            hero
            detailsCard
            sessionTypeCard
            gameCard
            startButton
            guidance
        }
        .padding(4)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Log a session")
                .font(.title2.bold())
                .foregroundColor(Theme.text)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Theme.panel2, Theme.panel], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.border, lineWidth: 0.5))
    }

    private var detailsCard: some View {
        LogSectionCard(title: "Session details") {
            VStack(alignment: .leading, spacing: 12) {
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

    private var guidance: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(Theme.muted)
            Text("When you hit Start, the app switches to rack logging. If you choose a past date, timers are turned off so you can backfill old sessions cleanly.")
                .font(.caption)
                .foregroundColor(Theme.text2)
        }
        .padding(14)
        .background(Theme.panel.opacity(0.75))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.5))
    }

    private var labelFieldPlaceholder: String {
        sessionType == "practice" ? "Practice note (optional)" : "Opponent / location (optional)"
    }

    private var trimmedLabel: String {
        label.trimmingCharacters(in: .whitespaces)
    }

    private var summaryText: String {
        let mode = sessionType == "practice" ? "Practice" : "Match"
        let gameText = game == "8ball" ? "8-ball" : "9-ball"
        return "\(mode) · \(gameText) · \(dateSummary)"
    }

    private var dateSummary: String {
        AppFormatters.shortDate(sessionDate)
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
