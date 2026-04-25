import SwiftUI
import UIKit

struct DrillsView: View {
    let onStartDrill: () -> Void
    @State private var searchText: String = ""
    @State private var selectedSkills: Set<String> = []
    private let tabBarClearance: CGFloat = 118

    private var filteredTemplates: [DrillTemplate] {
        DrillLibrary.templates.filter { template in
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let searchable = ([template.title, template.description] + template.primarySkills + template.secondarySkills)
                .joined(separator: " ")
            let matchesSearch = query.isEmpty || searchable.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            let allSkills = Set((template.primarySkills + template.secondarySkills).map { $0.lowercased() })
            let matchesSkills = selectedSkills.allSatisfy { skill in allSkills.contains(skill.lowercased()) }
            return matchesSearch && matchesSkills
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Drills")
                    .font(.largeTitle.bold())
                    .foregroundColor(Theme.text)
                    .padding(.top, 4)

                searchAndFilters

                VStack(spacing: 10) {
                    if filteredTemplates.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredTemplates) { template in
                            NavigationLink {
                                DrillDetailView(template: template, onStartDrill: onStartDrill)
                            } label: {
                                DrillTemplateRow(template: template)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, Layout.pagePadding)
            .padding(.bottom, tabBarClearance)
        }
        .background(Theme.bg)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var searchAndFilters: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Theme.muted)
                TextField("Search drills", text: $searchText)
                    .foregroundColor(Theme.text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption.weight(.bold))
                            .foregroundColor(Theme.muted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(Theme.panel2.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.6))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DrillLibrary.fargoSkills, id: \.self) { skill in
                        FilterSkillButton(skill: skill, isOn: selectedSkills.contains(skill)) {
                            if selectedSkills.contains(skill) { selectedSkills.remove(skill) } else { selectedSkills.insert(skill) }
                        }
                    }
                    if !selectedSkills.isEmpty {
                        Button("Clear") { selectedSkills.removeAll() }
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Theme.muted)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Theme.panel2.opacity(0.65))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No drills match that filter")
                .font(.headline.weight(.semibold))
                .foregroundColor(Theme.text)
            Text("Try clearing one skill or searching a broader term.")
                .font(.caption)
                .foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.panel2.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.border, lineWidth: 0.6))
    }
}

private struct DrillTemplateRow: View {
    let template: DrillTemplate

    var body: some View {
        HStack(spacing: 12) {
            DrillThumbnail(template: template)
                .frame(width: 92, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.6))

            VStack(alignment: .leading, spacing: 6) {
                Text(template.title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Theme.text)
                    .lineLimit(1)
                Text(template.description)
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                    .lineLimit(2)
                HStack(spacing: 7) {
                    ForEach(Array(template.primarySkills.prefix(3)), id: \.self) { skill in
                        drillBadge(skill, color: drillColor(skill))
                    }
                    Text(template.difficultyRangeText)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(Theme.text2)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(Theme.muted)
        }
        .padding(12)
        .background(Theme.panel2.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.border, lineWidth: 0.6))
    }
}

private struct DrillDetailView: View {
    @EnvironmentObject private var logStore: SessionLogStore
    @Environment(\.dismiss) private var dismiss
    let template: DrillTemplate
    let onStartDrill: () -> Void
    @State private var selectedLevel: DrillDifficultyLevel = .standard
    @State private var showPicture = false

    private var selectedDifficulty: DrillDifficulty {
        template.difficultyLevels.first(where: { $0.level == selectedLevel }) ?? template.standardDifficulty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                backButton
                detailHeader
                diagramButton
                skillsSection
                difficultySection
                instructionsSection
                startButton
            }
            .padding(.horizontal, Layout.pagePadding)
            .padding(.top, 8)
            .padding(.bottom, 128)
        }
        .background(Theme.bg)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { selectedLevel = template.standardDifficulty.level }
        .fullScreenCover(isPresented: $showPicture) {
            DrillPictureExpandedView(template: template, difficulty: selectedDifficulty)
        }
    }

    private var backButton: some View {
        Button { dismiss() } label: {
            HStack(spacing: 7) {
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.bold))
                Text("Drills")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(Theme.text2)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Theme.panel2.opacity(0.85))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Theme.border, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private var detailHeader: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(template.title)
                .font(.largeTitle.bold())
                .foregroundColor(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            Text(template.description)
                .font(.subheadline)
                .foregroundColor(Theme.text2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var diagramButton: some View {
        Button { showPicture = true } label: {
            DrillPictureView(template: template, ballCount: selectedDifficulty.ballCount)
                .frame(height: 222)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.border, lineWidth: 0.8))
                .overlay(alignment: .bottomTrailing) {
                    Text("Tap to expand")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.45))
                        .clipShape(Capsule())
                        .padding(10)
                }
        }
        .buttonStyle(.plain)
    }

    private var skillsSection: some View {
        SectionCard(title: "Skills") {
            VStack(alignment: .leading, spacing: 14) {
                skillGroup(title: "Fargo skills", subtitle: "Main parts of your game this drill trains", items: Array(template.primarySkills.prefix(3)), color: nil)
                Divider().overlay(Theme.border)
                skillGroup(title: "Practice focus", subtitle: "Secondary cues to pay attention to", items: Array(template.secondarySkills.prefix(3)), color: Theme.teal)
            }
        }
    }

    private var difficultySection: some View {
        SectionCard(title: "Difficulty") {
            VStack(alignment: .leading, spacing: 14) {
                DifficultyGradientSlider(levels: template.difficultyLevels, selectedLevel: $selectedLevel)
                HStack(spacing: 10) {
                    DrillInfoTile(label: "Balls", value: "\(selectedDifficulty.ballCount)", color: difficultyColor(for: selectedLevel))
                    VStack(alignment: .leading, spacing: 5) {
                        Text(selectedDifficulty.level.label)
                            .font(.caption.weight(.bold))
                            .foregroundColor(difficultyColor(for: selectedLevel))
                        Text(selectedDifficulty.constraint)
                            .font(.caption)
                            .foregroundColor(Theme.text2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Theme.panel2)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.5))
                }
            }
        }
    }

    private var instructionsSection: some View {
        SectionCard(title: "How to run it") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(template.instructions, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption.weight(.bold))
                            .foregroundColor(Theme.green)
                            .frame(width: 16, alignment: .center)
                        Text(item)
                            .font(.caption)
                            .foregroundColor(Theme.text2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var startButton: some View {
        Button {
            logStore.startDrillPractice(template: template, difficulty: selectedDifficulty)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            dismiss()
            onStartDrill()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.headline.weight(.black))
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Start drill")
                        .font(.headline)
                    Text("\(selectedDifficulty.level.label) · \(selectedDifficulty.ballCount) balls")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.82))
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.headline.weight(.bold))
            }
            .foregroundColor(.white)
            .padding(15)
            .background(LinearGradient(colors: [Theme.teal, Theme.blue], startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func skillGroup(title: String, subtitle: String, items: [String], color: Color?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.text)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(Theme.muted)
            }
            SkillChipRow(items: items) { item in color ?? drillColor(item) }
        }
    }
}

struct DrillLogActiveView: View {
    @EnvironmentObject private var store: SessionLogStore
    @EnvironmentObject private var historyStore: DataStore
    @State private var selectedTags: Set<String> = []
    @State private var ballsMade: Double = 0
    @State private var currentLevel: DrillDifficultyLevel = .standard
    @State private var showPicture = false
    @State private var toast: String?
    @State private var attemptsExpanded = false
    @Binding var showEndConfirm: Bool

    private let mistakeOptions = ["Potting", "Position", "Pattern", "Runout"]
    private var session: Session? { store.currentSession }
    private var template: DrillTemplate? { DrillLibrary.template(id: session?.drillID) }
    private var targetBallCount: Int { currentDifficulty?.ballCount ?? session?.drillBallCount ?? 0 }
    private var currentDifficulty: DrillDifficulty? {
        guard let template else { return nil }
        return template.difficultyLevels.first(where: { $0.level == currentLevel }) ?? template.standardDifficulty
    }
    private var attempts: Int { session?.drillAttempts ?? 0 }
    private var successes: Int { session?.drillSuccesses ?? 0 }
    private var misses: Int { session?.drillMisses ?? 0 }
    private var successRate: String { session?.drillSuccessRate.map { "\($0)%" } ?? "--" }
    private var canLogSuccess: Bool { Int(ballsMade) >= targetBallCount }
    private var canLogMiss: Bool { Int(ballsMade) < targetBallCount }

    var body: some View {
        if let session, session.isDrillPractice {
            VStack(alignment: .leading, spacing: 12) {
                practiceHeader(session)
                scorePanel(session)
                compactDifficulty
                mistakesPanel
                pottedPanel
                actionPanel
                attemptLog(session)
                if let toast {
                    Text(toast)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.green)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .transition(.opacity)
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 118)
            .onAppear { hydrateDifficulty(from: session) }
            .onChange(of: session.drillDifficulty) { _ in hydrateDifficulty(from: session) }
            .fullScreenCover(isPresented: $showPicture) {
                if let template, let currentDifficulty {
                    DrillPictureExpandedView(template: template, difficulty: currentDifficulty)
                }
            }
        } else {
            EmptyView()
        }
    }

    private func practiceHeader(_ session: Session) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(session.drillTitle ?? "Drill")
                        .font(.title3.bold())
                        .foregroundColor(Theme.text)
                        .lineLimit(2)
                    Text(metaLine(session))
                        .font(.caption.weight(.medium))
                        .foregroundColor(Theme.text2)
                }
                Spacer(minLength: 4)
                Button { showPicture = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.expand.vertical")
                            .font(.caption.weight(.bold))
                        Text("See layout")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundColor(Theme.teal)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Theme.teal.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Theme.teal.opacity(0.28), lineWidth: 0.6))
                }
                .buttonStyle(.plain)
            }

            if let label = session.drillTargetLabel {
                Text(label)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(Theme.amber)
            }
        }
        .padding(14)
        .background(LinearGradient(colors: [Theme.panel2, Theme.panel.opacity(0.92)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.border, lineWidth: 0.6))
    }

    private func scorePanel(_ session: Session) -> some View {
        TimelineView(.periodic(from: Date(), by: 1)) { _ in
            let elapsed = elapsedSince(store.sessionStart)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("W:L")
                        .font(.caption2.weight(.black))
                        .foregroundColor(Theme.muted)
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("\(successes)")
                            .foregroundColor(Theme.green)
                        Text(":")
                            .foregroundColor(Theme.text2)
                        Text("\(misses)")
                            .foregroundColor(Theme.red)
                    }
                    .font(.system(size: 42, weight: .black, design: .rounded).monospacedDigit())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    Text(AppFormatters.elapsed(elapsed))
                        .font(.headline.weight(.bold).monospacedDigit())
                        .foregroundColor(Theme.text)
                    Text("\(attempts) attempts · \(successRate)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.muted)
                    if let progress = session.drillTargetProgress {
                        ProgressView(value: Double(progress.current), total: Double(max(progress.target, 1)))
                            .tint(Theme.green)
                            .frame(width: 112)
                    }
                }
            }
            .padding(14)
            .background(Theme.panel2.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.border, lineWidth: 0.6))
        }
    }

    private var compactDifficulty: some View {
        HStack(spacing: 8) {
            Button { stepDifficulty(-1) } label: {
                Image(systemName: "minus")
                    .font(.caption.weight(.black))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .foregroundColor(Theme.text)
            .background(Theme.panel2)
            .clipShape(Circle())
            .disabled(currentDifficultyIndex <= 0)
            .opacity(currentDifficultyIndex <= 0 ? 0.35 : 1)

            Text(currentDifficulty?.level.label ?? "Difficulty")
                .font(.caption.weight(.black))
                .foregroundColor(difficultyColor(for: currentLevel))
            Text("· \(targetBallCount) balls")
                .font(.caption.weight(.semibold))
                .foregroundColor(Theme.text2)
            Spacer()
            Text("Difficulty")
                .font(.caption2.weight(.bold))
                .foregroundColor(Theme.muted)

            Button { stepDifficulty(1) } label: {
                Image(systemName: "plus")
                    .font(.caption.weight(.black))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .foregroundColor(Theme.text)
            .background(Theme.panel2)
            .clipShape(Circle())
            .disabled(currentDifficultyIndex >= maxDifficultyIndex)
            .opacity(currentDifficultyIndex >= maxDifficultyIndex ? 0.35 : 1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.panel2.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 0.5))
    }

    private var mistakesPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Mistakes")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Theme.text)
                Spacer()
                if !selectedTags.isEmpty {
                    Button("Clear") { selectedTags.removeAll() }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.muted)
                }
            }
            HStack(spacing: 7) {
                ForEach(mistakeOptions, id: \.self) { item in
                    MistakeSquareButton(title: item, isOn: selectedTags.contains(item), color: drillColor(item)) {
                        if selectedTags.contains(item) { selectedTags.remove(item) } else { selectedTags.insert(item) }
                    }
                }
            }
        }
        .padding(12)
        .background(Theme.panel2.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.border, lineWidth: 0.6))
    }

    private var pottedPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Potted")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Theme.text)
                Spacer()
                Text("\(Int(ballsMade))/\(targetBallCount)")
                    .font(.headline.weight(.bold).monospacedDigit())
                    .foregroundColor(pottedColor)
            }
            PottedAttemptSlider(value: $ballsMade, maxValue: max(targetBallCount, 1))
                .onChange(of: targetBallCount) { newValue in
                    ballsMade = min(ballsMade, Double(max(newValue, 0)))
                }
        }
        .padding(12)
        .background(Theme.panel2.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.border, lineWidth: 0.6))
    }

    private var pottedColor: Color {
        canLogSuccess ? Theme.green : Theme.amber
    }

    private var actionPanel: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                outcomeButton(title: "Miss", icon: "xmark", color: Theme.red, disabled: !canLogMiss) { recordCurrent(outcome: "miss") }
                outcomeButton(title: "Success", icon: "checkmark", color: Theme.green, disabled: !canLogSuccess) { recordCurrent(outcome: "success") }
            }
            Button { saveAttemptAndExit() } label: {
                Text("Save & Exit")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Theme.purple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Theme.purple.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.purple.opacity(0.28), lineWidth: 0.8))
            }
            .buttonStyle(.plain)
        }
    }

    private func outcomeButton(title: String, icon: String, color: Color, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption.weight(.black))
                Text(title)
                    .font(.headline.weight(.bold))
            }
            .foregroundColor(disabled ? Theme.muted : .black.opacity(0.82))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(disabled ? Theme.panel2 : color)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(disabled ? Theme.border : color.opacity(0.4), lineWidth: 0.8))
            .shadow(color: disabled ? Color.clear : color.opacity(0.22), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private func attemptLog(_ session: Session) -> some View {
        DisclosureGroup(isExpanded: $attemptsExpanded) {
            VStack(spacing: 7) {
                if session.racks.isEmpty {
                    Text("No attempts logged yet.")
                        .font(.subheadline)
                        .foregroundColor(Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    ForEach(session.racks.reversed()) { rack in
                        attemptRow(rack)
                    }
                }
            }
            .padding(.top, 8)
        } label: {
            HStack {
                Text("Attempts")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Theme.text)
                Spacer()
                Text("\(attempts)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundColor(Theme.muted)
            }
        }
        .tint(Theme.text2)
        .padding(14)
        .background(Theme.panel2.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.border, lineWidth: 0.6))
    }

    private func attemptRow(_ rack: Rack) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 9) {
                Text("#\(rack.index)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Theme.muted)
                    .frame(width: 34, alignment: .leading)
                Image(systemName: rack.drillOutcome == "success" ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(rack.drillOutcome == "success" ? Theme.green : Theme.red)
                Text("\(rack.drillBallsMade ?? 0)/\(rack.drillTargetBallCount ?? targetBallCount)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundColor(Theme.text)
                Spacer()
                if let difficulty = rack.drillDifficulty {
                    Text(DrillDifficultyLevel(rawValue: difficulty)?.label ?? difficulty)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(Theme.muted)
                }
            }
            if let tags = rack.drillTags, !tags.isEmpty {
                HStack(spacing: 5) {
                    ForEach(tags, id: \.self) { tag in
                        drillBadge(tag, color: drillColor(tag))
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(10)
        .background(Theme.bg.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func recordCurrent(outcome: String) {
        guard (outcome == "success" && canLogSuccess) || (outcome == "miss" && canLogMiss) else { return }
        let target = targetBallCount
        let made = outcome == "success" ? target : min(Int(ballsMade), max(target - 1, 0))
        if store.recordDrillAttempt(outcome: outcome, tags: Array(selectedTags).sorted(), ballsMade: made, targetBallCount: target, difficulty: currentLevel.rawValue) {
            UINotificationFeedbackGenerator().notificationOccurred(outcome == "success" ? .success : .warning)
            toast = outcome == "success" ? "Success logged." : "Miss logged."
            ballsMade = 0
            selectedTags.removeAll()
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                toast = nil
            }
        }
    }

    private func saveAttemptAndExit() {
        let target = targetBallCount
        let made = min(Int(ballsMade), target)
        let outcome = made >= target ? "success" : "miss"
        _ = store.recordDrillAttempt(outcome: outcome, tags: Array(selectedTags).sorted(), ballsMade: made, targetBallCount: target, difficulty: currentLevel.rawValue)
        Task { await store.endSession(savingTo: historyStore) }
    }

    private func hydrateDifficulty(from session: Session) {
        if let level = session.drillDifficultyLevel {
            currentLevel = level
        }
        ballsMade = min(ballsMade, Double(max(session.drillBallCount ?? 0, 0)))
    }

    private func stepDifficulty(_ delta: Int) {
        guard let template else { return }
        let nextIndex = min(max(currentDifficultyIndex + delta, 0), template.difficultyLevels.count - 1)
        let difficulty = template.difficultyLevels[nextIndex]
        currentLevel = difficulty.level
        ballsMade = min(ballsMade, Double(difficulty.ballCount))
        store.updateDrillDifficulty(level: difficulty.level, ballCount: difficulty.ballCount)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private var currentDifficultyIndex: Int {
        template?.difficultyLevels.firstIndex(where: { $0.level == currentLevel }) ?? 0
    }

    private var maxDifficultyIndex: Int {
        max((template?.difficultyLevels.count ?? 1) - 1, 0)
    }

    private func metaLine(_ session: Session) -> String {
        [currentDifficulty?.level.label ?? session.drillDifficultyLabel, "\(targetBallCount) balls"]
            .joined(separator: " · ")
    }

    private func elapsedSince(_ start: Date?) -> TimeInterval {
        guard let start else { return 0 }
        return max(0, Date().timeIntervalSince(start))
    }
}

private struct DrillPictureExpandedView: View {
    @Environment(\.dismiss) private var dismiss
    let template: DrillTemplate
    let difficulty: DrillDifficulty

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(template.title)
                            .font(.headline.weight(.bold))
                            .foregroundColor(Theme.text)
                        Text("\(difficulty.level.label) · \(difficulty.ballCount) balls")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(difficultyColor(for: difficulty.level))
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.black))
                            .foregroundColor(Theme.text)
                            .frame(width: 34, height: 34)
                            .background(Theme.panel2)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)

                DrillPictureView(template: template, ballCount: difficulty.ballCount)
                    .aspectRatio(1.9, contentMode: .fit)
                    .padding(.horizontal, 14)

                Spacer(minLength: 0)
            }
            .padding(.top, 18)
        }
    }
}

private struct DifficultyGradientSlider: View {
    let levels: [DrillDifficulty]
    @Binding var selectedLevel: DrillDifficultyLevel

    var selectedIndex: Int { levels.firstIndex(where: { $0.level == selectedLevel }) ?? 0 }

    var body: some View {
        VStack(spacing: 9) {
            GeometryReader { geo in
                let count = max(levels.count, 1)
                let inset: CGFloat = 14
                let width = max(geo.size.width - inset * 2, 1)
                let step = count > 1 ? width / CGFloat(count - 1) : 0
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(colors: [Theme.green, Theme.amber, Theme.red], startPoint: .leading, endPoint: .trailing))
                        .frame(width: width, height: 10)
                        .position(x: inset + width / 2, y: 20)
                        .opacity(0.9)
                    ForEach(Array(levels.enumerated()), id: \.element.id) { idx, difficulty in
                        Circle()
                            .fill(selectedIndex == idx ? Color.white : Theme.bg)
                            .overlay(Circle().stroke(difficultyColor(for: difficulty.level), lineWidth: selectedIndex == idx ? 3 : 2))
                            .frame(width: selectedIndex == idx ? 26 : 18, height: selectedIndex == idx ? 26 : 18)
                            .position(x: inset + CGFloat(idx) * step, y: 20)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let x = min(max(value.location.x - inset, 0), width)
                            let idx = min(max(Int(round(x / max(step, 1))), 0), count - 1)
                            selectedLevel = levels[idx].level
                        }
                )
            }
            .frame(height: 40)

            HStack(spacing: 4) {
                ForEach(levels) { difficulty in
                    Text(difficulty.level.label)
                        .font(.system(size: 9, weight: difficulty.level == selectedLevel ? .black : .semibold))
                        .foregroundColor(difficulty.level == selectedLevel ? difficultyColor(for: difficulty.level) : Theme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

private struct PottedAttemptSlider: View {
    @Binding var value: Double
    let maxValue: Int

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let inset: CGFloat = 12
                let width = max(geo.size.width - inset * 2, 1)
                let total = max(maxValue, 1)
                let step = width / CGFloat(total)
                let selectedX = inset + CGFloat(value / Double(total)) * width
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.border.opacity(0.85))
                        .frame(width: width, height: 10)
                        .position(x: inset + width / 2, y: 18)
                    Capsule()
                        .fill(LinearGradient(colors: [Theme.red, Theme.amber, Theme.green], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(1, selectedX - inset), height: 10)
                        .position(x: inset + max(1, selectedX - inset) / 2, y: 18)
                    ForEach(0...total, id: \.self) { idx in
                        Circle()
                            .fill(idx == Int(value) ? Color.white : Theme.bg)
                            .overlay(Circle().stroke(idx == Int(value) ? Theme.green : Theme.border, lineWidth: idx == Int(value) ? 3 : 1.5))
                            .frame(width: idx == Int(value) ? 22 : 13, height: idx == Int(value) ? 22 : 13)
                            .position(x: inset + CGFloat(idx) * step, y: 18)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            let x = min(max(drag.location.x - inset, 0), width)
                            value = Double(min(max(Int(round(x / max(step, 1))), 0), total))
                        }
                )
            }
            .frame(height: 36)

            HStack {
                Text("0")
                Spacer()
                Text("Target \(maxValue)")
            }
            .font(.caption2.weight(.semibold))
            .foregroundColor(Theme.muted)
        }
    }
}

private struct FilterSkillButton: View {
    let skill: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(skill)
                .font(.caption.weight(.bold))
                .foregroundColor(isOn ? .black.opacity(0.82) : drillColor(skill))
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(isOn ? drillColor(skill) : drillColor(skill).opacity(0.12))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(drillColor(skill).opacity(0.32), lineWidth: 0.6))
        }
        .buttonStyle(.plain)
    }
}

private struct MistakeSquareButton: View {
    let title: String
    let isOn: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(isOn ? .black.opacity(0.82) : color)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(isOn ? color : color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(isOn ? 0.55 : 0.28), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
    }
}

private struct DrillInfoTile: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundColor(Theme.muted)
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
                .monospacedDigit()
        }
        .frame(width: 92, alignment: .leading)
        .padding(12)
        .background(Theme.panel2)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.5))
    }
}

private struct DrillThumbnail: View {
    let template: DrillTemplate
    var body: some View {
        DrillPictureView(template: template, ballCount: template.standardDifficulty.ballCount)
            .allowsHitTesting(false)
    }
}

private struct DrillPictureView: View {
    let template: DrillTemplate
    let ballCount: Int

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                tableBackground
                pockets(in: size)
                drillZones(template.pictureID, in: size)
                ForEach(balls(for: template.pictureID, ballCount: ballCount)) { ball in
                    ballView(ball, in: size)
                }
            }
        }
    }

    private var tableBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(LinearGradient(colors: [Color(red: 0.02, green: 0.31, blue: 0.24), Color(red: 0.01, green: 0.18, blue: 0.16)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.13), lineWidth: 2).padding(5))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.34), lineWidth: 6).padding(4))
    }

    private func pockets(in size: CGSize) -> some View {
        let insetX = max(13, size.width * 0.045)
        let insetY = max(12, size.height * 0.08)
        let radius = max(5, min(size.width, size.height) * 0.04)
        let points = [
            CGPoint(x: insetX, y: insetY), CGPoint(x: size.width / 2, y: insetY * 0.72), CGPoint(x: size.width - insetX, y: insetY),
            CGPoint(x: insetX, y: size.height - insetY), CGPoint(x: size.width / 2, y: size.height - insetY * 0.72), CGPoint(x: size.width - insetX, y: size.height - insetY)
        ]
        return ForEach(Array(points.enumerated()), id: \.offset) { _, point in
            Circle().fill(Color.black.opacity(0.88)).frame(width: radius * 2, height: radius * 2).position(point)
        }
    }

    @ViewBuilder
    private func drillZones(_ id: String, in size: CGSize) -> some View {
        if id == "one_side_pattern" {
            zone(x: 0.52, y: 0.12, w: 0.38, h: 0.76, label: "Do not cross", color: Theme.red, in: size)
            centerLine(in: size, color: Theme.red)
        } else if id == "centerline_control" {
            zone(x: 0.14, y: 0.41, w: 0.72, h: 0.18, label: "Center lane", color: Theme.blue, in: size)
        } else if id == "rail_avoidance" {
            zone(x: 0.10, y: 0.09, w: 0.80, h: 0.15, label: "Avoid rail", color: Theme.red, in: size)
            zone(x: 0.10, y: 0.76, w: 0.80, h: 0.15, label: "Avoid rail", color: Theme.red, in: size)
        }
    }

    private func centerLine(in size: CGSize, color: Color) -> some View {
        Rectangle().fill(color.opacity(0.55)).frame(width: 1.5, height: size.height * 0.78).position(x: size.width * 0.5, y: size.height * 0.5)
    }

    private func zone(x: Double, y: Double, w: Double, h: Double, label: String, color: Color, in size: CGSize) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(color.opacity(0.12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.42), style: StrokeStyle(lineWidth: 1, dash: [6, 5])))
            .overlay(alignment: .topLeading) {
                Text(label)
                    .font(.system(size: max(7, min(size.width, size.height) * 0.04), weight: .bold))
                    .foregroundColor(color.opacity(0.8))
                    .padding(6)
            }
            .frame(width: size.width * w, height: size.height * h)
            .position(x: size.width * (x + w / 2), y: size.height * (y + h / 2))
    }

    private func balls(for id: String, ballCount: Int) -> [PictureBall] {
        let count = max(1, min(ballCount, 9))
        let coords: [(Double, Double)]
        let cuePoint: (Double, Double)
        switch id {
        case "l_drill":
            cuePoint = (0.24, 0.76)
            coords = [(0.36,0.76),(0.48,0.76),(0.60,0.76),(0.72,0.76),(0.72,0.64),(0.72,0.52),(0.72,0.40),(0.72,0.28),(0.60,0.28)]
        case "one_side_pattern":
            cuePoint = (0.24, 0.50)
            coords = [(0.20,0.25),(0.39,0.31),(0.31,0.49),(0.42,0.67),(0.22,0.75),(0.36,0.18),(0.18,0.58)]
        case "stop_shot_ladder":
            cuePoint = (0.16, 0.50)
            coords = [(0.30,0.50),(0.41,0.50),(0.52,0.50),(0.63,0.50),(0.74,0.50),(0.84,0.50),(0.91,0.50)]
        case "centerline_control":
            cuePoint = (0.50, 0.50)
            coords = [(0.22,0.25),(0.78,0.28),(0.34,0.72),(0.66,0.75),(0.50,0.23),(0.25,0.52),(0.76,0.55)]
        case "rail_avoidance":
            cuePoint = (0.24, 0.50)
            coords = [(0.34,0.35),(0.52,0.42),(0.70,0.35),(0.44,0.65),(0.66,0.62),(0.54,0.53),(0.31,0.58)]
        default:
            cuePoint = (0.28, 0.52)
            coords = [(0.22,0.26),(0.40,0.66),(0.58,0.31),(0.76,0.70),(0.70,0.43),(0.48,0.50),(0.33,0.39),(0.62,0.60)]
        }
        return [PictureBall(id: "cue", number: 0, x: cuePoint.0, y: cuePoint.1)] + Array(coords.prefix(count)).enumerated().map { idx, coord in
            PictureBall(id: "ball-\(idx + 1)", number: idx + 1, x: coord.0, y: coord.1)
        }
    }

    private func ballView(_ ball: PictureBall, in size: CGSize) -> some View {
        let diameter = max(7, min(15, min(size.width, size.height) * 0.062))
        return ZStack {
            if ball.number == 0 {
                Circle().fill(Color.white)
            } else if ball.number == 9 {
                Circle().fill(Color.white)
                Rectangle()
                    .fill(poolBallColor(ball.number))
                    .frame(width: diameter, height: diameter * 0.42)
                    .clipShape(Circle())
                Circle().stroke(poolBallColor(ball.number), lineWidth: max(1, diameter * 0.08))
            } else {
                Circle().fill(poolBallColor(ball.number))
                if ball.number != 8 {
                    Circle().fill(Color.white.opacity(0.94)).frame(width: diameter * 0.54, height: diameter * 0.54)
                }
            }
            Text(ball.number == 0 ? "C" : "\(ball.number)")
                .font(.system(size: max(4, diameter * 0.32), weight: .black, design: .rounded))
                .foregroundColor(ball.number == 8 ? .white : .black.opacity(0.84))
        }
        .frame(width: diameter, height: diameter)
        .shadow(color: .black.opacity(0.32), radius: 3, x: 0, y: 2)
        .position(x: size.width * ball.x, y: size.height * ball.y)
    }
}

private struct PictureBall: Identifiable {
    let id: String
    let number: Int
    let x: Double
    let y: Double
}

private struct SkillChipRow: View {
    let items: [String]
    let colorProvider: (String) -> Color

    var body: some View {
        ChipGrid(items: items) { item in drillBadge(item, color: colorProvider(item)) }
    }
}

private struct ChipGrid<Content: View>: View {
    let items: [String]
    let content: (String) -> Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 7, alignment: .leading)], alignment: .leading, spacing: 7) {
            ForEach(items, id: \.self) { item in
                content(item).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private func drillBadge(_ text: String, color: Color) -> some View {
    Text(text)
        .font(.caption2.weight(.bold))
        .foregroundColor(color)
        .lineLimit(1)
        .minimumScaleFactor(0.78)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(color.opacity(0.13))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.28), lineWidth: 0.5))
}

private func drillColor(_ name: String) -> Color {
    switch name.lowercased() {
    case "potting", "red": return Theme.red
    case "position", "blue": return Theme.blue
    case "pattern", "teal": return Theme.teal
    case "runout", "purple": return Theme.purple
    case "overall", "fundamentals", "green": return Theme.green
    case "break", "orange", "yellow", "amber": return Theme.amber
    default: return Theme.text2
    }
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

private func poolBallColor(_ number: Int) -> Color {
    switch number {
    case 1, 9: return Color(red: 0.96, green: 0.78, blue: 0.18)
    case 2: return Color(red: 0.16, green: 0.45, blue: 0.88)
    case 3: return Color(red: 0.88, green: 0.18, blue: 0.24)
    case 4: return Color(red: 0.45, green: 0.24, blue: 0.78)
    case 5: return Color(red: 0.95, green: 0.48, blue: 0.12)
    case 6: return Color(red: 0.18, green: 0.58, blue: 0.25)
    case 7: return Color(red: 0.50, green: 0.10, blue: 0.12)
    case 8: return Color.black
    default: return Color.white
    }
}
