import SwiftUI

struct WatchSessionStartView: View {
    @EnvironmentObject private var client: WatchConnectivityClient
    @EnvironmentObject private var sessionStore: WatchSessionStore

    @State private var sessionMode: String = "practice"
    @State private var selectedGame: String = "8ball"
    @State private var selectedOpponent: String = "Other"
    @State private var selectedTargetCount: Int = 3
    @State private var selectedDrillID: String = ""
    @State private var showOpponentPicker = false
    @State private var showTargetEditor = false
    @State private var showDrillPicker = false
    @State private var suppressStartUntil: Date = .distantPast

    private let cardBackground = Color(red: 0.16, green: 0.16, blue: 0.17)

    private var liveDrills: [WatchDrillTemplatePayload] {
        client.snapshot?.availableDrills ?? []
    }

    private var drills: [WatchDrillTemplatePayload] {
        if !liveDrills.isEmpty { return liveDrills }
        if !sessionStore.cachedDrills.isEmpty { return sessionStore.cachedDrills }
        return WatchDrillCatalog.fallbackTemplates
    }

    private var selectedDrill: WatchDrillTemplatePayload? {
        drills.first(where: { $0.id == selectedDrillID }) ?? drills.first
    }

    private var opponents: [String] {
        let names = client.snapshot?.availableOpponents ?? ["Other"]
        return names.isEmpty ? ["Other"] : names
    }

    private var canStart: Bool {
        if sessionMode == "practice" { return selectedDrill != nil }
        return !selectedGame.isEmpty
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(sessionMode == "practice" ? "Quick Practice" : "Quick Log")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.94))
                Spacer()
            }
            .padding(.top, -12)
            .padding(.bottom, 2)

            HStack(spacing: 8) {
                modeBadgeButton
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 52)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(cardBackground))
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button {
                    registerNonStartTap()
                    if sessionMode == "practice" {
                        showTargetEditor = true
                    } else {
                        selectedGame = selectedGame == "8ball" ? "9ball" : "8ball"
                    }
                    WKInterfaceDevice.current().play(.click)
                } label: {
                    modeTrailingBadge
                }
                .buttonStyle(.plain)
            }

            Button {
                registerNonStartTap()
                if sessionMode == "practice" {
                    showDrillPicker = true
                } else {
                    showOpponentPicker = true
                }
                WKInterfaceDevice.current().play(.click)
            } label: {
                HStack {
                    Text(rowPrimaryText)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(rowAccentColor)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.38))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .frame(height: 42)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(cardBackground))
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                guard Date() >= suppressStartUntil else { return }
                WKInterfaceDevice.current().play(.start)
                if sessionMode == "practice" {
                    guard let selectedDrill else { return }
                    client.startDrillPractice(drill: selectedDrill, targetCount: selectedTargetCount)
                } else {
                    client.startSession(
                        game: selectedGame,
                        opponent: selectedOpponent.isEmpty ? "Other" : selectedOpponent
                    )
                }
            } label: {
                Text(sessionMode == "practice" ? "Start Practice" : "Start Session")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(canStart ? Color(red: 0.37, green: 0.92, blue: 0.83) : Color(white: 0.34))
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
            .disabled(!canStart)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .onAppear {
            if selectedDrillID.isEmpty {
                selectedDrillID = drills.first?.id ?? ""
            }
        }
        .onChange(of: drills.map(\.id)) { _, _ in
            if drills.contains(where: { $0.id == selectedDrillID }) == false {
                selectedDrillID = drills.first?.id ?? ""
            }
        }
        .sheet(isPresented: $showTargetEditor) {
            WatchTargetPickerSheet(targetCount: $selectedTargetCount)
        }
        .sheet(isPresented: $showOpponentPicker) {
            WatchOpponentPickerSheet(opponents: opponents, selectedOpponent: $selectedOpponent)
        }
        .sheet(isPresented: $showDrillPicker) {
            WatchDrillPickerSheet(drills: drills, selectedDrillID: $selectedDrillID)
        }
    }

    private var modeBadgeButton: some View {
        Button {
            registerNonStartTap()
            sessionMode = sessionMode == "practice" ? "match" : "practice"
            WKInterfaceDevice.current().play(.click)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text("Mode")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.45))
                Text(sessionMode == "practice" ? "Practice" : "Match")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(sessionMode == "practice" ? Color(red: 0.37, green: 0.92, blue: 0.83) : Color(red: 0.98, green: 0.75, blue: 0.25))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func registerNonStartTap() {
        suppressStartUntil = Date().addingTimeInterval(0.2)
    }

    @ViewBuilder
    private var modeTrailingBadge: some View {
        if sessionMode == "practice" {
            targetBadge
        } else {
            gameBadge
        }
    }

    private var rowPrimaryText: String {
        if sessionMode == "practice" {
            return selectedDrill?.title ?? "Drill"
        }
        return selectedOpponent.isEmpty ? "Opponent" : selectedOpponent
    }

    private var rowAccentColor: Color {
        if sessionMode == "practice" {
            return selectedDrill == nil ? .white.opacity(0.4) : .teal
        }
        return selectedOpponent.isEmpty ? .white.opacity(0.4) : Color(red: 0.98, green: 0.75, blue: 0.25)
    }

    private var gameBadge: some View {
        ZStack {
            Circle()
                .fill(selectedGame == "8ball" ? Color.black : Color(red: 0.98, green: 0.82, blue: 0.12))
                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1.5))
            Text(selectedGame == "8ball" ? "8" : "9")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(selectedGame == "8ball" ? Color.white : Color.black.opacity(0.84))
        }
        .frame(width: 30, height: 30)
    }

    private var targetBadge: some View {
        VStack(alignment: .leading, spacing: 2) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.98, green: 0.82, blue: 0.12))
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1.5))
                Text("\(selectedTargetCount)")
                    .font(.system(size: selectedTargetCount >= 10 ? 10 : 12, weight: .black, design: .rounded))
                    .foregroundStyle(.black.opacity(0.84))
            }
            .frame(width: 30, height: 30)
        }
    }
}

private struct WatchTargetPickerSheet: View {
    @Binding var targetCount: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Target Successes")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)

            Picker("Target", selection: $targetCount) {
                ForEach(1...50, id: \.self) { value in
                    Text("\(value)").tag(value)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()

            Button("Done") {
                WKInterfaceDevice.current().play(.click)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.37, green: 0.92, blue: 0.83))
        }
        .padding(.horizontal, 4)
        .background(Color.black.ignoresSafeArea())
    }
}

private struct WatchDrillPickerSheet: View {
    let drills: [WatchDrillTemplatePayload]
    @Binding var selectedDrillID: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Drill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)

            List(drills, id: \.id) { drill in
                Button {
                    selectedDrillID = drill.id
                    WKInterfaceDevice.current().play(.click)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(drill.title)
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            if let standard = drill.difficultyLevels.first(where: { $0.level == "standard" }) ?? drill.difficultyLevels.first {
                                Text(drill.difficultySummary(standard))
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.45))
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        if selectedDrillID == drill.id {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.teal)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(red: 0.12, green: 0.12, blue: 0.13))
                )
            }
            .listStyle(.carousel)
            .scrollContentBackground(.hidden)
            .background(Color.black)
        }
        .padding(.horizontal, 4)
        .background(Color.black.ignoresSafeArea())
    }
}

private struct WatchOpponentPickerSheet: View {
    let opponents: [String]
    @Binding var selectedOpponent: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Opponent")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)

            List(opponents, id: \.self) { name in
                Button {
                    selectedOpponent = name
                    WKInterfaceDevice.current().play(.click)
                    dismiss()
                } label: {
                    HStack {
                        Text(name)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Spacer()
                        if selectedOpponent == name {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.teal)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(red: 0.12, green: 0.12, blue: 0.13))
                )
            }
            .listStyle(.carousel)
            .scrollContentBackground(.hidden)
            .background(Color.black)
        }
        .padding(.horizontal, 4)
        .background(Color.black.ignoresSafeArea())
    }
}
