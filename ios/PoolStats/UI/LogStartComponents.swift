import SwiftUI

struct SessionChoiceCard: View {
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

struct CompactModeButton: View {
    let title: String
    let isOn: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption.weight(.bold))
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.caption2.weight(.bold))
            }
            .foregroundColor(isOn ? color : Theme.text2)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(isOn ? color.opacity(0.16) : Theme.panel2.opacity(0.7))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isOn ? color.opacity(0.7) : Theme.border, lineWidth: 0.7))
        }
        .buttonStyle(.plain)
    }
}

struct SelectedDrillPickerCard: View {
    let template: DrillTemplate
    let difficulty: DrillDifficulty
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(template.title)
                        .font(.headline.weight(.bold))
                        .foregroundColor(Theme.text)
                        .lineLimit(1)
                    Text(template.difficultySummary(difficulty))
                        .font(.caption.weight(.bold))
                        .foregroundColor(accent)
                        .lineLimit(1)
                }
                Text(template.description)
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    ForEach(Array(template.primarySkills.prefix(3)), id: \.self) { skill in
                        Text(skill)
                            .font(.caption2.weight(.bold))
                            .foregroundColor(logStartSkillColor(skill))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(logStartSkillColor(skill).opacity(0.14))
                            .clipShape(Capsule())
                    }
                }
            }
            Spacer(minLength: 0)
            VStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.callout.weight(.bold))
                Text("Find")
                    .font(.caption2.weight(.bold))
            }
            .foregroundColor(Theme.text)
            .frame(width: 48, height: 58)
            .background(Theme.panel2)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.7))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(accent.opacity(0.55), lineWidth: 0.9))
    }
}

struct DrillSelectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDrillID: String
    @Binding var searchText: String

    private var filteredTemplates: [DrillTemplate] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return DrillLibrary.templates }
        return DrillLibrary.templates.filter { template in
            let searchable = ([template.title, template.description] + template.primarySkills + template.secondarySkills)
                .joined(separator: " ")
            return searchable.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    searchField
                    if filteredTemplates.isEmpty {
                        Text("No drills match that search.")
                            .font(.caption)
                            .foregroundColor(Theme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(Theme.panel2)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    } else {
                        ForEach(filteredTemplates) { template in
                            Button {
                                selectedDrillID = template.id
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                dismiss()
                            } label: {
                                DrillSelectorRow(template: template, isSelected: selectedDrillID == template.id)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(Layout.pagePadding)
            }
            .background(Theme.bg)
            .navigationTitle("Choose drill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.caption.weight(.bold))
                .foregroundColor(Theme.muted)
            TextField("Search drills", text: $searchText)
                .foregroundColor(Theme.text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundColor(Theme.muted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(Theme.panel2)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.6))
    }
}

private struct DrillSelectorRow: View {
    let template: DrillTemplate
    let isSelected: Bool

    private var accent: Color {
        logStartDifficultyColor(template.standardDifficulty.level)
    }

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(template.title)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Theme.text)
                    Spacer(minLength: 0)
                    Text(template.difficultyRangeText)
                        .font(.caption2.weight(.bold))
                        .foregroundColor(accent)
                }
                Text(template.description)
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    ForEach(Array(template.primarySkills.prefix(3)), id: \.self) { skill in
                        Text(skill)
                            .font(.caption2.weight(.bold))
                            .foregroundColor(logStartSkillColor(skill))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(logStartSkillColor(skill).opacity(0.14))
                            .clipShape(Capsule())
                    }
                }
            }
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3.weight(.bold))
                .foregroundColor(isSelected ? accent : Theme.muted)
        }
        .padding(12)
        .background(isSelected ? accent.opacity(0.12) : Theme.panel2.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? accent.opacity(0.55) : Theme.border, lineWidth: 0.7))
    }
}

struct SuccessRepWheel: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    private var values: [Int] { Array(range) }

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: "chevron.up")
                .font(.caption2.weight(.bold))
                .foregroundColor(Theme.muted)
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 9) {
                        ForEach(values, id: \.self) { number in
                            Button {
                                value = number
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                Text("\(number)")
                                    .font(.system(size: number == value ? 24 : 15, weight: .black, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundColor(number == value ? .black.opacity(0.85) : Theme.text2)
                                    .frame(width: number == value ? 58 : 42, height: number == value ? 58 : 42)
                                    .background(number == value ? Theme.green : Theme.panel2)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(number == value ? Theme.green.opacity(0.7) : Theme.border, lineWidth: 0.8))
                            }
                            .buttonStyle(.plain)
                            .id(number)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .frame(width: 76, height: 150)
                .background(Theme.panel2.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 38).stroke(Theme.border, lineWidth: 0.7))
                .onAppear {
                    DispatchQueue.main.async { proxy.scrollTo(value, anchor: .center) }
                }
                .onChange(of: value) { newValue in
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
                .foregroundColor(Theme.muted)
        }
    }
}

func logStartDifficultyColor(_ level: DrillDifficultyLevel) -> Color {
    switch level {
    case .beginner: return Theme.green
    case .easy: return Theme.teal
    case .standard: return Theme.amber
    case .hard: return Color.orange
    case .expert: return Theme.red
    }
}

func logStartSkillColor(_ skill: String) -> Color {
    switch skill.lowercased() {
    case "potting": return Theme.red
    case "position": return Theme.blue
    case "pattern": return Theme.teal
    case "runout": return Theme.purple
    case "overall", "fundamentals": return Theme.green
    default: return Theme.text2
    }
}
