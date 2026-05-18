import SwiftUI

struct SessionChoiceCard: View {
    let title: String
    let ballNumber: Int
    let isOn: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                GameBallBadge(number: ballNumber)

                Text(LocalizedStringKey(title))
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

private struct GameBallBadge: View {
    let number: Int

    private var isEightBall: Bool { number == 8 }

    var body: some View {
        ZStack {
            Circle()
                .fill(isEightBall ? Color.black : Color(red: 0.98, green: 0.82, blue: 0.12))
                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1.5))
            Text("\(number)")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(isEightBall ? Color.white : Color.black.opacity(0.84))
        }
        .frame(width: 34, height: 34)
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
                Text(LocalizedStringKey(title))
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
    let accent: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "scope")
                .font(.headline.weight(.bold))
                .foregroundColor(accent)
                .frame(width: 34, height: 34)
                .background(accent.opacity(0.15))
                .clipShape(Circle())
                .overlay(Circle().stroke(accent.opacity(0.38), lineWidth: 0.7))

            VStack(alignment: .leading, spacing: 3) {
                Text("Selected drill")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(Theme.muted)
                Text(template.localizedTitle)
                    .font(.headline.weight(.bold))
                    .foregroundColor(Theme.text)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.caption.weight(.bold))
                Text("Change")
                    .font(.caption2.weight(.bold))
            }
            .foregroundColor(Theme.text)
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(Theme.panel2)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Theme.border, lineWidth: 0.7))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.panel2.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.5), lineWidth: 0.8))
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
            let searchable = template.searchableText
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
                    Text(template.localizedTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Theme.text)
                    Spacer(minLength: 0)
                    Text(template.difficultyRangeText)
                        .font(.caption2.weight(.bold))
                        .foregroundColor(accent)
                }
                Text(template.localizedDescription)
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    ForEach(Array(template.localizedPrimarySkills.prefix(3)), id: \.self) { skill in
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

    @State private var dragStartValue: Int?
    @State private var lastFeedbackValue: Int?
    @State private var dragOffset: CGFloat = 0

    private let itemSpacing: CGFloat = 50
    private let wheelHeight: CGFloat = 150

    private var visibleNumbers: [Int] {
        let lower = max(range.lowerBound, value - 3)
        let upper = min(range.upperBound, value + 3)
        return Array(lower...upper)
    }

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: "chevron.up")
                .font(.caption2.weight(.bold))
                .foregroundColor(Theme.muted)

            ZStack {
                RoundedRectangle(cornerRadius: 38, style: .continuous)
                    .fill(Theme.panel2.opacity(0.6))
                    .overlay(RoundedRectangle(cornerRadius: 38).stroke(Theme.border, lineWidth: 0.7))

                Capsule()
                    .stroke(Theme.green.opacity(0.28), lineWidth: 1.2)
                    .frame(width: 62, height: 62)

                ForEach(visibleNumbers, id: \.self) { number in
                    let isSelected = number == value
                    Text("\(number)")
                        .font(.system(size: isSelected ? 24 : 15, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(isSelected ? .black.opacity(0.85) : Theme.text2)
                        .frame(width: isSelected ? 58 : 42, height: isSelected ? 58 : 42)
                        .background(isSelected ? Theme.green : Theme.panel2)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(isSelected ? Theme.green.opacity(0.7) : Theme.border, lineWidth: 0.8))
                        .shadow(color: isSelected ? Theme.green.opacity(0.28) : .clear, radius: 8, y: 3)
                        .contentShape(Circle())
                    .offset(y: CGFloat(number - value) * itemSpacing + dragOffset)
                    .opacity(opacity(for: number))
                    .zIndex(isSelected ? 1 : 0)
                }
            }
            .frame(width: 76, height: wheelHeight)
            .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged(handleDragChanged)
                    .onEnded { drag in
                        endDrag(drag)
                    }
            )
            .animation(.spring(response: 0.22, dampingFraction: 0.82), value: value)

            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
                .foregroundColor(Theme.muted)
        }
    }

    private func choose(_ number: Int) {
        let nextValue = clamped(number)
        guard value != nextValue else { return }
        value = nextValue
        dragOffset = 0
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func handleDragChanged(_ drag: DragGesture.Value) {
        if dragStartValue == nil {
            dragStartValue = value
            lastFeedbackValue = value
        }

        let start = dragStartValue ?? value
        let steps = Int((-drag.translation.height / itemSpacing).rounded())
        let nextValue = clamped(start + steps)
        let appliedSteps = nextValue - start
        let residualOffset = drag.translation.height + CGFloat(appliedSteps) * itemSpacing
        dragOffset = min(itemSpacing, max(-itemSpacing, residualOffset))

        guard value != nextValue else { return }
        withAnimation(.spring(response: 0.18, dampingFraction: 0.86)) {
            value = nextValue
        }
        if lastFeedbackValue != nextValue {
            UISelectionFeedbackGenerator().selectionChanged()
            lastFeedbackValue = nextValue
        }
    }

    private func endDrag(_ drag: DragGesture.Value) {
        if abs(drag.translation.height) < 6, abs(drag.translation.width) < 6 {
            let tappedOffset = Int(((drag.location.y - wheelHeight / 2) / itemSpacing).rounded())
            choose(value + tappedOffset)
        }

        dragStartValue = nil
        lastFeedbackValue = nil
        withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
            dragOffset = 0
        }
    }

    private func clamped(_ number: Int) -> Int {
        min(max(number, range.lowerBound), range.upperBound)
    }

    private func opacity(for number: Int) -> Double {
        switch abs(number - value) {
        case 0: return 1
        case 1: return 0.9
        default: return 0.55
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
    case "potting", "准度": return Theme.red
    case "position", "走位": return Theme.blue
    case "pattern", "路线": return Theme.teal
    case "runout", "清台": return Theme.purple
    case "overall", "fundamentals", "综合", "基本功": return Theme.green
    default: return Theme.text2
    }
}
