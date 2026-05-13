import SwiftUI
import UIKit

struct DrillDetailView: View {
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
        .appBackSwipeEnabled()
        .onAppear { selectedLevel = template.standardDifficulty.level }
        .fullScreenCover(isPresented: $showPicture) {
            DrillPictureExpandedView(template: template, difficulty: selectedDifficulty)
        }
    }

    private var backButton: some View {
        AppBackButton(label: "Drills")
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
            DrillPictureView(template: template, difficulty: selectedDifficulty)
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "scope")
                    .font(.caption.weight(.black))
                    .foregroundColor(Theme.teal)
                    .frame(width: 24, height: 24)
                    .background(Theme.teal.opacity(0.14))
                    .clipShape(Circle())
                Text("Training focus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.text)
                Spacer(minLength: 0)
            }

            compactSkillRow(label: "Fargo", items: Array(template.primarySkills.prefix(3)), color: nil)
            compactSkillRow(label: "Cues", items: Array(template.secondarySkills.prefix(3)), color: Theme.teal)
        }
        .padding(12)
        .background(Theme.panel.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 0.5))
    }

    private var difficultySection: some View {
        SectionCard(title: "Difficulty") {
            VStack(alignment: .leading, spacing: 14) {
                DifficultyGradientSlider(levels: template.difficultyLevels, selectedLevel: $selectedLevel)
                HStack(spacing: 10) {
                    DrillInfoTile(label: template.countUnit.title, value: "\(selectedDifficulty.ballCount)", color: difficultyColor(for: selectedLevel))
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
                    Text(template.difficultySummary(selectedDifficulty))
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

    private func compactSkillRow(label: String, items: [String], color: Color?) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .font(.caption2.weight(.black))
                .foregroundColor(Theme.muted)
                .textCase(.uppercase)
                .frame(width: 44, alignment: .leading)
                .padding(.top, 5)
            SkillChipRow(items: items) { item in color ?? drillColor(item) }
        }
    }
}
