import SwiftUI

struct MeSettingsView: View {
    @EnvironmentObject private var profileStore: PlayerProfileStore
    @EnvironmentObject private var goalsStore: GoalsStore
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var opponentStore: OpponentStore
    @Environment(\.dismiss) private var dismiss

    @State private var baselineFargoText: String = ""
    @State private var pendingDedication: DedicationLevel?
    @State private var nicknameText: String = ""

    var body: some View {
        VStack(spacing: 12) {
            // Nickname
            SectionCard(title: "Nickname") {
                VStack(alignment: .leading, spacing: 6) {
                    TextField("e.g. Haoran", text: $nicknameText)
                        .font(.subheadline)
                        .foregroundColor(Theme.text)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Theme.panel2)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 0.5))
                        .onChange(of: nicknameText) { value in
                            profileStore.updateProfile { $0.nickname = value }
                        }
                    Text("Shown above your score in the lite scoreboard. Defaults to \"Me\".")
                        .font(.caption2)
                        .foregroundColor(Theme.muted)
                }
            }

            // Skill level
            SectionCard(title: "Skill level") {
                VStack(spacing: 0) {
                    ForEach(SkillLevel.allCases) { level in
                        let selected = profileStore.profile.skillLevel == level
                        Button {
                            profileStore.updateProfile {
                                $0.skillLevel = level
                                $0.baselineFargo = level.defaultFargo
                            }
                            baselineFargoText = "\(profileStore.profile.clampedBaseline)"
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selected ? "record.circle.fill" : "circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(selected ? Theme.purple : Theme.border)
                                Text(level.label)
                                    .font(.subheadline)
                                    .foregroundColor(selected ? Theme.text : Theme.text2)
                                Spacer(minLength: 0)
                                Text(level.fargoRange)
                                    .font(.caption2.monospacedDigit())
                                    .foregroundColor(selected ? Theme.purple : Theme.muted)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(selected ? Theme.purple.opacity(0.1) : Theme.panel2)
                                    .cornerRadius(6)
                            }
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if level != SkillLevel.allCases.last {
                            Divider().overlay(Theme.border)
                        }
                    }

                    Divider().overlay(Theme.border)

                    HStack {
                        Text("My Fargo rating")
                            .font(.subheadline)
                            .foregroundColor(Theme.text2)
                        Spacer(minLength: 0)
                        TextField("0–850", text: $baselineFargoText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.subheadline.monospacedDigit())
                            .foregroundColor(Theme.text)
                            .frame(width: 56)
                            .onChange(of: baselineFargoText) { value in
                                let filtered = value.filter(\.isNumber)
                                if filtered != value { baselineFargoText = filtered }
                                profileStore.updateProfile {
                                    $0.baselineFargo = min(max(Int(filtered) ?? 0, 0), 850)
                                }
                            }
                        Text("/ 850")
                            .font(.caption2)
                            .foregroundColor(Theme.muted)
                    }
                    .padding(.vertical, 10)
                }
            }

            // Dedication
            SectionCard(title: "Dedication") {
                VStack(spacing: 0) {
                    ForEach(DedicationLevel.allCases) { level in
                        let selected = profileStore.profile.dedication == level
                        let accent = dedicationAccentColor(level)
                        Button {
                            guard level != profileStore.profile.dedication else { return }
                            pendingDedication = level
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selected ? "record.circle.fill" : "circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(selected ? accent : Theme.border)
                                Text(level.label)
                                    .font(.subheadline)
                                    .foregroundColor(selected ? Theme.text : Theme.text2)
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if level != DedicationLevel.allCases.last {
                            Divider().overlay(Theme.border)
                        }
                    }
                }
            }

            // Game & frequency
            SectionCard(title: "Game & frequency") {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Primary game")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Theme.muted)
                        HStack(spacing: 8) {
                            ForEach(PrimaryGame.allCases) { game in
                                let selected = profileStore.profile.primaryGame == game
                                Button {
                                    profileStore.updateProfile { $0.primaryGame = game }
                                } label: {
                                    Text(game.label)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(selected ? Theme.text : Theme.text2)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 40)
                                        .background(selected ? Theme.teal.opacity(0.12) : Theme.panel2)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(selected ? Theme.teal : Theme.border,
                                                        lineWidth: selected ? 1.2 : 0.5)
                                        )
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("How often per week")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Theme.muted)
                        HStack(spacing: 8) {
                            ForEach(FrequencyBand.allCases) { band in
                                let selected = profileStore.profile.weeklyFrequencyBand == band
                                Button {
                                    profileStore.updateProfile { $0.weeklyFrequencyBand = band }
                                } label: {
                                    VStack(spacing: 2) {
                                        Text(band.frequency)
                                            .font(.subheadline.weight(.bold).monospacedDigit())
                                            .foregroundColor(selected ? Theme.text : Theme.text2)
                                        Text(band.sublabel)
                                            .font(.caption2)
                                            .foregroundColor(selected ? Theme.amber : Theme.muted)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(selected ? Theme.amber.opacity(0.12) : Theme.panel2)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selected ? Theme.amber : Theme.border,
                                                    lineWidth: selected ? 1.2 : 0.5)
                                    )
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            Button {
                profileStore.requestRerunOnboarding()
                dismiss()
            } label: {
                Text("Re-run onboarding")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.purple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.purple.opacity(0.12))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.purple.opacity(0.45), lineWidth: 0.8))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            SectionCard(title: "Me") {
                VStack(spacing: 10) {
                    infoRow(label: "Favorite opponent", value: favoriteOpponent)
                    infoRow(label: "Biggest leak", value: Analytics.biggestLeakSummary(Analytics.matchRacks(store.sessions)))
                    infoRow(label: "Latest session", value: latestSessionText)
                }
            }
        }
        .task {
            baselineFargoText = "\(profileStore.profile.clampedBaseline)"
            nicknameText = profileStore.profile.nickname
        }
        .alert("Regenerate starter goals?", isPresented: Binding(
            get: { pendingDedication != nil },
            set: { if !$0 { pendingDedication = nil } }
        )) {
            Button("Keep current goals", role: .cancel) {
                if let next = pendingDedication {
                    profileStore.updateProfile { $0.dedication = next }
                }
                pendingDedication = nil
            }
            Button("Regenerate") {
                if let next = pendingDedication {
                    profileStore.updateProfile { $0.dedication = next }
                    let starter = goalsStore.starterGoals(from: profileStore.profile)
                    goalsStore.applyStarterGoals(starter, replaceExistingStarter: true)
                }
                pendingDedication = nil
            }
        } message: {
            Text("Use your new dedication level to regenerate starter-generated goals?")
        }
    }

    private func dedicationAccentColor(_ level: DedicationLevel) -> Color {
        switch level {
        case .justForFun: return Theme.muted
        case .maybe: return Theme.teal
        case .neutral: return Theme.teal
        case .yes: return Theme.green
        case .veryMuch: return Theme.purple
        }
    }

    private var favoriteOpponent: String {
        opponentStore.favoriteOpponent(from: store.sessions)
    }

    private var latestSessionText: String {
        guard let latest = store.sessions.max(by: { $0.ts < $1.ts }) else { return "—" }
        let opp = latest.opponent.trimmingCharacters(in: .whitespaces)
        let game = latest.gameLabel
        let mode = latest.typeLabel
        let bits = [mode, game, opp.isEmpty ? nil : "vs \(opp)"]
        return bits.compactMap { $0 }.joined(separator: " · ")
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(Theme.muted)
            Spacer()
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundColor(Theme.text)
        }
    }
}
